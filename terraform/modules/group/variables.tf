terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 4.0.0"
    }
  }
}

variable "realm" {
  type = object({
    id = string
  })
  description = "The realm the group will be created in."
}
variable "name" {
  type        = string
  description = "The name of the group."
}
variable "realm_roles" {
  type        = list(string)
  description = "The names of any realm roles to attach to the group."
  default     = []
}
variable "client_roles" {
  type        = list(string)
  description = "The IDs of any client roles to attach to the group."
  default     = []
}
