Site estático na AWS com HTTPS (S3 + CloudFront + ACM + Cloudflare)

Guia passo a passo para publicar um site estático com HTTPS em um domínio próprio, usando Amazon S3 (privado) + CloudFront + ACM e Cloudflare DNS.
Sem dados sensíveis: use os placeholders e substitua pelos seus valores.

Visão geral

Arquitetura recomendada (produção)
S3 (privado) → CloudFront (OAC) → Seu domínio (DNS na Cloudflare) → HTTPS com certificado ACM (us-east-1).

Por que assim?

HTTPS fim-a-fim

Melhor desempenho (CDN)

Bucket privado (segurança)

Pré-requisitos

Conta AWS com acesso a S3, CloudFront e ACM.

Zona DNS do seu domínio gerenciada na Cloudflare.

Um site estático (ex.: index.html) pronto para upload.

Variáveis que você vai trocar:

<AWS_ACCOUNT_ID> – ID da sua conta AWS

<REGIAO_S3> – ex.: us-east-1 ou sa-east-1

<BUCKET_NAME> – ex.: site-exemplo

<CLOUDFRONT_DIST_ID> – ID da distribuição

<CF_DOMAIN_NAME> – domínio do CloudFront, ex.: dxxx.cloudfront.net

<DOMINIO> – seu domínio, ex.: exemplo.com

<SUBDOMINIO> – ex.: www (resulta em www.exemplo.com)

Passo 1 — Criar o bucket S3 (privado) e enviar os arquivos

S3 → Create bucket

Bucket name: <BUCKET_NAME>

Region: <REGIAO_S3>

Block Public Access: ON (padrão)

Faça upload do seu index.html (e demais assets) na raiz do bucket.

Não habilite Static website hosting no S3 quando usar CloudFront + OAC (vamos servir via REST API do S3).

Passo 2 — Criar a distribuição CloudFront (com OAC)

CloudFront → Create distribution

Origin

Origin domain: https://<BUCKET_NAME>.s3.<REGIAO_S3>.amazonaws.com (REST do S3; selecione a opção correspondente)

Origin access: Use an origin access control (recommended) → Create new OAC

Origin protocol policy: HTTPS only

Minimum origin SSL protocol: TLSv1.2

Default behavior

Viewer protocol policy: Redirect HTTP to HTTPS

Allowed HTTP versions: HTTP/2 e HTTP/3 (se disponível)

Settings

Default root object: index.html

Create distribution

Após criar, o console vai sugerir uma Bucket policy. Aplique-a no S3 (próximo passo).

Passo 3 — Aplicar a Bucket Policy para a OAC (S3 privado)

S3 → Bucket <BUCKET_NAME> → Permissions → Bucket policy.
Cole a política sugerida pelo CloudFront (ou adapte este modelo):

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontOACRead",
      "Effect": "Allow",
      "Principal": { "Service": "cloudfront.amazonaws.com" },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::<BUCKET_NAME>/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::<AWS_ACCOUNT_ID>:distribution/<CLOUDFRONT_DIST_ID>"
        }
      }
    }
  ]
}


Block Public Access permanece ON.

Passo 4 — Emitir o certificado no ACM (us-east-1)

ACM (região us-east-1) → Request a public certificate

Domain names: "<SUBDOMINIO>.<DOMINIO>" (e/ou "<DOMINIO>")

Validation: DNS validation

O ACM exibirá CNAMEs de validação.

Vá à Cloudflare → DNS → Add record:

Type: CNAME

Name: (o Record name sem o domínio repetido)

Target: Record value do ACM

Proxy: DNS only (nuvem cinza)

Aguarde ~1–10 min até o certificado ficar Issued.

Passo 5 — Prender o domínio e o certificado na distribuição

CloudFront → Distribution → Settings/General → Edit

Alternate domain name (CNAME): "<SUBDOMINIO>.<DOMINIO>"

Custom SSL certificate: selecione seu cert Issued (us-east-1)

Save changes (aguarde status Deployed)

Passo 6 — Apontar o DNS da Cloudflare

Cloudflare → DNS → Add record

Type: CNAME

Name: <SUBDOMINIO>

Target: <CF_DOMAIN_NAME> (ex.: dxxx.cloudfront.net)

Proxy: DNS only (recomendado p/ simplicidade)

Se usar Proxy ON (laranja), ajuste a Cloudflare para SSL/TLS = Full (strict).

Passo 7 — Testes rápidos

Acesse o domínio do CloudFront:
https://<CF_DOMAIN_NAME>/index.html

Depois o seu domínio:
https://<SUBDOMINIO>.<DOMINIO>/

Linha de comando (opcional):

# Certificado apresentado
curl -I https://<SUBDOMINIO>.<DOMINIO>/

# DNS do CNAME
dig +short CNAME <SUBDOMINIO>.<DOMINIO> @1.1.1.1


Se publicar arquivos novos, faça Invalidation: CloudFront → Invalidations → Create → /*.

Troubleshooting (erros comuns)

AccessDenied (XML) ao acessar /

Faltou Default root object = index.html

Bucket privado sem OAC/bucket policy correta

Arquivo index.html não está na raiz do bucket

Timeout/ETIMEDOUT

Origin configurado como S3 Website endpoint com HTTPS only (website não fala HTTPS)

Use REST + OAC (acima) ou se optar por website endpoint, defina HTTP only no origin

Certificado não aparece no CloudFront

Cert não está em us-east-1 ou ainda está Pending validation

Loop/redirecionamento com Cloudflare (proxy laranja)

Em Cloudflare, use SSL/TLS = Full (strict)

Certifique o CNAME do ACM/validações como DNS only

Rota SPA quebra (404/403)

Em Error pages (CloudFront), mapeie 403/404 → /index.html (response code 200)

(Opcional) Alternativa rápida: S3 Website + Cloudflare “Flexible”

Não recomendado para produção (sem TLS fim-a-fim), mas útil para MVPs.

Origin: S3 Website endpoint (…s3-website-<regiao>.amazonaws.com)

Cloudflare: Proxy ON + SSL/TLS = Flexible

Viewer: Redirect HTTP → HTTPS

Prefira a arquitetura REST + OAC para produção.

(Opcional) Anexos — Exemplos prontos
1) Tabela de DNS (Cloudflare)
Tipo	Name	Target/Value	Proxy
CNAME	<SUBDOMINIO>	<CF_DOMAIN_NAME>	DNS only
CNAME	_xxxx.<SUBDOMINIO>	_yyyy.acm-validations.aws	DNS only
2) Política do bucket (modelo)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontOACRead",
      "Effect": "Allow",
      "Principal": { "Service": "cloudfront.amazonaws.com" },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::<BUCKET_NAME>/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::<AWS_ACCOUNT_ID>:distribution/<CLOUDFRONT_DIST_ID>"
        }
      }
    }
  ]
}

Conclusão

Seguindo os passos acima, seu site estático passa a responder em HTTPS no seu domínio customizado via CloudFront, com S3 privado e OAC, certificado ACM (us-east-1) e DNS na Cloudflare.
Essa implantação equilibra segurança, performance e manutenibilidade — e evita expor dados sensíveis: todos os exemplos usam placeholders.
