locals {
  default_tags = {
    managed-by = "Terraform"
    owner      = "backstage"
    repo       = "backstage/keycloak"
    realm      = "nonprod"
  }
}

data "aws_ssm_parameter" "smtp_credentials" {
  name = "/backstage/keycloak/smtp-credentials"
}

module "realm" {
  source = "../../modules/realm"

  name   = "nonprod"
  config = yamldecode(file("${path.module}/../../../realms/nonprod.yaml"))

  smtp = {
    host     = "smtp.gmail.com"
    port     = 587
    starttls = true
    username = jsondecode(data.aws_ssm_parameter.smtp_credentials.value)["username"]
    password = jsondecode(data.aws_ssm_parameter.smtp_credentials.value)["password"]
  }
}
