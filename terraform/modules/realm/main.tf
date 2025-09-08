data "aws_ssm_parameter" "smtp_credentials" {
  name = "/backstage/keycloak/smtp-credentials"
}

resource "keycloak_realm" "default" {
  realm             = var.name
  display_name      = var.display_name
  display_name_html = "<img src=\"https://bts-crew.com/images/bts-logo.png\">"
  ssl_required      = "external"

  # Themes
  login_theme = "bts-keycloak-theme"

  # Login settings
  registration_allowed     = false
  reset_password_allowed   = true
  remember_me              = true
  verify_email             = true
  login_with_email_allowed = true
  duplicate_emails_allowed = false

  # Authentication settings
  password_policy = "notUsername and notEmail and notContainsUsername and passwordHistory(3) and length(5)"

  # Sessions
  access_token_lifespan                = var.access_token_lifespan
  sso_session_idle_timeout             = "${7 * 24}h"
  sso_session_max_lifespan             = "${14 * 24}h"
  sso_session_idle_timeout_remember_me = "${30 * 24}h"
  sso_session_max_lifespan_remember_me = "${90 * 24}h"
  offline_session_idle_timeout         = "${30 * 24}h"

  # Security
  security_defenses {
    headers {
      x_frame_options                     = "DENY"
      content_security_policy             = "frame-src 'self'; frame-ancestors 'self'; object-src 'none';"
      content_security_policy_report_only = ""
      x_content_type_options              = "nosniff"
      x_robots_tag                        = "none"
      x_xss_protection                    = "1; mode=block"
      strict_transport_security           = "max-age=31536000; includeSubDomains"
    }
    brute_force_detection {
      permanent_lockout                = false
      max_login_failures               = 30
      wait_increment_seconds           = 60
      quick_login_check_milli_seconds  = 1000
      minimum_quick_login_wait_seconds = 60
      max_failure_wait_seconds         = 900
      failure_reset_time_seconds       = 43200
    }
  }

  # SMTP
  smtp_server {
    host     = "smtp.gmail.com"
    port     = 587
    starttls = true

    from                  = "no-reply@bts-crew.com"
    from_display_name     = "Backstage Auth"
    reply_to              = "sec@bts-crew.com"
    reply_to_display_name = "Backstage Secretary"

    auth {
      username = jsondecode(data.aws_ssm_parameter.smtp_credentials.value)["username"]
      password = jsondecode(data.aws_ssm_parameter.smtp_credentials.value)["password"]
    }
  }
}

resource "keycloak_realm_events" "default" {
  realm_id = keycloak_realm.default.id

  events_enabled = true

  admin_events_enabled         = true
  admin_events_details_enabled = true

  events_listeners = ["jboss-logging", "metrics-listener"]
}

resource "keycloak_authentication_bindings" "default" {
  count = var.use_custom_auth_flows ? 1 : 0

  realm_id     = keycloak_realm.default.id
  browser_flow = keycloak_authentication_flow.browser.alias
}

########################################################################################################################
# User profile attributes
########################################################################################################################
resource "keycloak_realm_user_profile" "default" {
  realm_id = keycloak_realm.default.id

  attribute {
    name         = "username"
    display_name = "$${username}"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        min = 3
        max = 255
      }
    }

    validator {
      name   = "username-prohibited-characters"
      config = {}
    }

    validator {
      name   = "up-username-not-idn-homograph"
      config = {}
    }
  }

  attribute {
    name         = "email"
    display_name = "$${email}"
    multi_valued = false

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name   = "email"
      config = {}
    }

    validator {
      name = "length"
      config = {
        max = 255
      }
    }
  }

  attribute {
    name         = "firstName"
    display_name = "$${firstName}"
    multi_valued = false

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        max = 255
      }
    }

    validator {
      name   = "person-name-prohibited-characters"
      config = {}
    }
  }

  attribute {
    name         = "lastName"
    display_name = "$${lastName}"
    multi_valued = false

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        max = 255
      }
    }

    validator {
      name   = "person-name-prohibited-characters"
      config = {}
    }
  }

  attribute {
    name         = "mobile"
    display_name = "Mobile number"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "pattern"
      config = {
        pattern       = "^(?:(?:\\(?(?:0(?:0|11)\\)?[\\s-]?\\(?|\\+)44\\)?[\\s-]?(?:\\(?0\\)?[\\s-]?)?)|(?:\\(?0))(?:(?:\\d{5}\\)?[\\s-]?\\d{4,5})|(?:\\d{4}\\)?[\\s-]?(?:\\d{5}|\\d{3}[\\s-]?\\d{3}))|(?:\\d{3}\\)?[\\s-]?\\d{3}[\\s-]?\\d{3,4})|(?:\\d{2}\\)?[\\s-]?\\d{4}[\\s-]?\\d{4}))(?:[\\s-]?(?:x|ext\\.?|\\#)\\d{3,4})?$"
        error-message = "Please enter a valid UK mobile number"
      }
    }
  }

  attribute {
    name         = "extension"
    display_name = "Backstage phone extension"

    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }

  group {
    name                = "user-metadata"
    display_header      = "User metadata"
    display_description = "Attributes, which refer to user metadata"
  }
}
