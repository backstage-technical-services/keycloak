terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "bnjns-terraform"
    key            = "backstage/keycloak/nonprod.tfstate"
    dynamodb_table = "bnjns-terraform-lock"
    encrypt        = true
    region         = "eu-west-1"
    profile        = "backstage"
  }
}


########################################################################################################################
# AWS
########################################################################################################################
provider "aws" {
  region  = "eu-west-1"
  profile = "backstage"

  default_tags {
    tags = local.default_tags
  }
}

########################################################################################################################
# Keycloak
########################################################################################################################
data "aws_ssm_parameter" "keycloak_config" {
  name = "/backstage/keycloak/terraform-config"
}
locals {
  keycloak_config = jsondecode(data.aws_ssm_parameter.keycloak_config.value)
}
provider "keycloak" {
  url           = "https://auth.bts-crew.com"
  client_id     = local.keycloak_config["clientId"]
  client_secret = local.keycloak_config["clientSecret"]
}
