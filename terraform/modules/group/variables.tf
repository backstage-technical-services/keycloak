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
  description = "The realm the client will be created in."
}
variable "name" {
  type        = string
  description = "An optional human-friendly name of the client."
  default     = null
}
variable "client_roles" {
  type        = map(list(string))
  description = "Any client roles to attach to the group; the key is the client ID and the value is the list of roles."
  default     = {}
}
