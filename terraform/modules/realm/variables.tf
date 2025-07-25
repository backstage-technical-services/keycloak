terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.1.0"
    }
  }
}

variable "name" {
  type = string
}
variable "display_name" {
  type = string
}
variable "use_custom_auth_flows" {
  type    = bool
  default = true
}

// Token config
variable "access_token_lifespan" {
  type    = string
  default = "5m"
}
variable "sso_session_idle_timeout" {
  type    = string
  default = "30m"
}
