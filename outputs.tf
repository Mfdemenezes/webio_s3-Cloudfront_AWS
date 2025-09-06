output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "website_url" {
  description = "URL do site via CloudFront"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "cloudfront_url" {
  description = "URL padrão do CloudFront"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "custom_domain_url" {
  description = "URL do domínio customizado (se configurado)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "Domínio customizado não configurado"
}

output "s3_website_url" {
  description = "URL direta do S3 Website"
  value       = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}

output "s3_website_domain" {
  description = "Domínio do S3 Website"
  value       = aws_s3_bucket_website_configuration.site.website_domain
}

output "uploaded_files" {
  description = "Lista de arquivos enviados para o S3 (sem arquivos ocultos)"
  value = [
    # Arquivos do site (na raiz)
    aws_s3_object.index.key,
    aws_s3_object.curriculo_english.key,
    aws_s3_object.curriculo_portugues.key,
    aws_s3_object.foto_capa.key,
    # Arquivos Terraform (em pasta separada)
    aws_s3_object.main_tf.key,
    aws_s3_object.providers_tf.key,
    aws_s3_object.variables_tf.key,
    aws_s3_object.outputs_tf.key,
    aws_s3_object.terraform_tfvars.key
  ]
}
