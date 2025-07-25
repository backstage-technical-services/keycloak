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
variable "restrict_access" {
  type        = bool
  description = "When enabled, users will need to be given the `client-access` client role in order to be able to use/access this client."
  default     = false
}
variable "enabled_flows" {
  type = object({
    authorization_code                  = optional(bool, false)
    implicit                            = optional(bool, false)
    client_credentials                  = optional(bool, false)
    resource_owner_password_credentials = optional(bool, false)
    oauth_device_authorization          = optional(bool, false)
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
variable "service_account_roles" {
  type        = map(list(string))
  description = "Any roles to attach to the client's service account; the key is the client ID and the value is the list of roles. Requires the `client_credentials` flow."
  default     = {}
}
