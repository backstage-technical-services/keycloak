terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

variable "name" {
  type        = string
  description = "The ID of the realm."
}

variable "ssl_required" {
  type    = string
  default = "external"

  validation {
    condition     = contains(["none", "external", "all"], var.ssl_required)
    error_message = "The value of var.ssl_required must be one of: none, external, all."
  }
}

variable "smtp" {
  type = object({
    host     = string
    port     = number
    starttls = optional(bool, false)
    username = optional(string)
    password = optional(string)
  })
}

variable "config" {
  type = object({
    display-name        = string
    default-access-mode = optional(string, "open")

    tokens = object({
      access-lifespan = string
    })

    auth = optional(object({
      enable-flows = optional(bool, true)
    }), {})

    federation = optional(object({
      read-only = optional(bool, false)
    }), {})

    groups = optional(list(object({
      name = string
      roles = optional(list(object({
        name   = string
        client = optional(string)
      })), [])
    })), [])

    clients = optional(list(object({
      name         = string
      display-name = optional(string)
      public       = optional(bool, false)
      access-mode  = optional(string)
      auth-flows = optional(object({
        standard                   = optional(bool, false)
        implicit                   = optional(bool, false)
        client-credentials         = optional(bool, false)
        direct-access-grants       = optional(bool, false)
        oauth-device-authorization = optional(bool, false)
      }), {})
      redirect-urls        = optional(list(string), [])
      logout-redirect-urls = optional(list(string), [])
      roles = optional(list(object({
        name        = string
        description = optional(string)
      })), [])
      service-account-roles = optional(list(object({
        name   = string
        client = string
      })), [])
    })), [])
  })

  validation {
    condition = (
      contains(["open", "restricted"], var.config["default-access-mode"]) ||
      contains([for group in var.config.groups : group.name], var.config["default-access-mode"])
    )
    error_message = "The `default-access-mode` value must be open, restricted, or a group declared in groups."
  }

  validation {
    condition = alltrue([
      for client in var.config.clients :
      client["access-mode"] == null ||
      contains(["open", "restricted"], client["access-mode"]) ||
      contains([for group in var.config.groups : group.name], client["access-mode"])
    ])
    error_message = "Each client `access-mode` must be open, restricted, a group declared in groups, or omitted."
  }

  validation {
    condition     = alltrue([for group in var.config.groups : !contains(["open", "restricted", "LDAP"], group.name)])
    error_message = "The group names open, restricted and LDAP are reserved."
  }
}
