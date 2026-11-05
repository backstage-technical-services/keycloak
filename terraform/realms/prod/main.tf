locals {
  default_tags = {
    managed-by = "Terraform"
    owner      = "backstage"
    repo       = "backstage/keycloak"
    realm      = "prod"
  }
}

data "aws_ssm_parameter" "smtp_credentials" {
  name = "/backstage/keycloak/smtp-credentials"
}

module "realm" {
  source = "../../modules/realm"

  name   = "prod"
  config = yamldecode(file("${path.module}/../../../realms/prod.yaml"))

  smtp = {
    host     = "smtp.gmail.com"
    port     = 587
    starttls = true
    username = jsondecode(data.aws_ssm_parameter.smtp_credentials.value)["username"]
    password = jsondecode(data.aws_ssm_parameter.smtp_credentials.value)["password"]
  }
}
