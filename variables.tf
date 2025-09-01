variable "region" {
  type = string
}

variable "bucket_name" {
  type        = string
  description = "Nome único global do bucket S3"
}
variable "price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "CloudFront price class (PriceClass_100/200/All)"
}

variable "spa_routing" {
  type        = bool
  default     = true
  description = "Redirecionar 403/404 para /index.html"
}

variable "enable_logging" {
  type        = bool
  default     = false
  description = "Habilitar logs do CloudFront"
}
