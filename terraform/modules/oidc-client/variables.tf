terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
  }
}

variable "realm" {
  type = object({
    id = string
  })
  description = "The realm the client will be created in."
}
variable "client_id" {
  type        = string
  description = "The unique ID of the client."
}
variable "name" {
  type        = string
  description = "An optional human-friendly name of the client."
  default     = null
}
variable "public" {
  type        = bool
  description = "When enabled the client type will be `public`, otherwise the type will be `confidential`."
  default     = false
}
variable "access_mode" {
  type        = string
  description = "When anything other than `open`, users will need to be given the `client-access` client role in order to be able to use/access this client."
  default     = "open"
}
variable "enabled_flows" {
  type = object({
    standard                   = optional(bool, false)
    implicit                   = optional(bool, false)
    client_credentials         = optional(bool, false)
    direct_access_grants       = optional(bool, false)
    oauth_device_authorization = optional(bool, false)
  })
  description = "The authentication flows that should be enabled."
  default     = {}
}

variable "redirect_urls" {
  type        = list(string)
  description = "The URL patterns that browsers can redirect to after a successful log in."
  default     = []
}
variable "logout_redirect_urls" {
  type        = list(string)
  description = "The URL patterns that browsers can redirect to after a successful log out."
  default     = []
}

variable "client_roles" {
  type = list(object({
    name        = string
    description = optional(string)
  }))
  description = "Any roles to create for this specific client."
  default     = []
}
