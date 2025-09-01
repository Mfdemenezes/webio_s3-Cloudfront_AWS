data "aws_caller_identity" "me" {}

# ---------------- S3 (privado) ----------------
resource "aws_s3_bucket" "site" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Enforce ownership (ACLs desligadas)
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.site.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

# Bloqueia acesso público (será liberado para website)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# Configuração de Website
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # Para SPA routing
  }

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# (Opcional) Versionamento
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration { status = "Enabled" }
}

# ---------------- Sem ACM - usando HTTPS padrão do CloudFront ----------------
# Para domínio customizado, seria necessário ACM, mas vamos usar só CloudFront URL

# ---------------- CloudFront OAC ----------------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------------- CloudFront Distribution ----------------
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  comment             = "Static site ${var.bucket_name}"
  price_class         = var.price_class
  default_root_object = "index.html"

  origin {
    origin_id                = "s3-origin"
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    # Cache policy gerenciada “CachingOptimized”
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    # CORS/headers extras? use response/req policies gerenciadas conforme necessidade.
  }

  dynamic "custom_error_response" {
    for_each = var.spa_routing ? [1] : []
    content {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    }
  }

  dynamic "custom_error_response" {
    for_each = var.spa_routing ? [1] : []
    content {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    }
  }

  # TLS padrão do CloudFront (*.cloudfront.net)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Sem aliases - usando apenas URL do CloudFront

  # (Opcional) Logging
  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      bucket          = "${aws_s3_bucket.site.bucket}.s3.amazonaws.com"
      include_cookies = false
      prefix          = "cf-logs/"
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  depends_on = [
    aws_s3_bucket_public_access_block.this,
    aws_s3_bucket_ownership_controls.this
  ]
}

# ---------------- S3 Policy: acesso público para website ----------------
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

# ---------------- Upload automático de TODOS os arquivos (exceto ocultos) ----------------

# Arquivos do site (index.html na raiz para CloudFront)
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  etag         = filemd5("index.html")
  depends_on   = [aws_s3_bucket_policy.this]
}

resource "aws_s3_object" "curriculo_english" {
  bucket       = aws_s3_bucket.site.id
  key          = "Curriculo_English.pdf"
  source       = "Curriculo_English.pdf"
  content_type = "application/pdf"
  etag         = filemd5("Curriculo_English.pdf")
  depends_on   = [aws_s3_bucket_policy.this]
}

resource "aws_s3_object" "curriculo_portugues" {
  bucket       = aws_s3_bucket.site.id
  key          = "Curriculo_Portugues.pdf"
  source       = "Curriculo_Portugues.pdf"
  content_type = "application/pdf"
  etag         = filemd5("Curriculo_Portugues.pdf")
  depends_on   = [aws_s3_bucket_policy.this]
}

resource "aws_s3_object" "foto_capa" {
  bucket       = aws_s3_bucket.site.id
  key          = "foto_capa.png"
  source       = "foto_capa.png"
  content_type = "image/png"
  etag         = filemd5("foto_capa.png")
  depends_on   = [aws_s3_bucket_policy.this]
}

# Arquivos Terraform
resource "aws_s3_object" "main_tf" {
  bucket       = aws_s3_bucket.site.id
  key          = "terraform/main.tf"
  source       = "main.tf"
  content_type = "text/plain"
  etag         = filemd5("main.tf")
  depends_on   = [aws_s3_bucket_policy.this]
}

resource "aws_s3_object" "providers_tf" {
  bucket       = aws_s3_bucket.site.id
  key          = "terraform/providers.tf"
  source       = "providers.tf"
  content_type = "text/plain"
  etag         = filemd5("providers.tf")
  depends_on   = [aws_s3_bucket_policy.this]
}

resource "aws_s3_object" "variables_tf" {
  bucket       = aws_s3_bucket.site.id
  key          = "terraform/variables.tf"
  source       = "variables.tf"
  content_type = "text/plain"
  etag         = filemd5("variables.tf")
  depends_on   = [aws_s3_bucket_policy.this]
}

resource "aws_s3_object" "outputs_tf" {
  bucket       = aws_s3_bucket.site.id
  key          = "terraform/outputs.tf"
  source       = "outputs.tf"
  content_type = "text/plain"
  etag         = filemd5("outputs.tf")
  depends_on   = [aws_s3_bucket_policy.this]
}

resource "aws_s3_object" "terraform_tfvars" {
  bucket       = aws_s3_bucket.site.id
  key          = "terraform/terraform.tfvars"
  source       = "terraform.tfvars"
  content_type = "text/plain"
  etag         = filemd5("terraform.tfvars")
  depends_on   = [aws_s3_bucket_policy.this]
}

# Site será acessado via URL do CloudFront (sem domínio customizado)
