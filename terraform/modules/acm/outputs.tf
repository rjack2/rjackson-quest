output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}

output "domain_validation_options" {
  value = {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}
