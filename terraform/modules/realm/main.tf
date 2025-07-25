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

  # Tokens
  access_token_lifespan    = var.access_token_lifespan
  sso_session_idle_timeout = var.sso_session_idle_timeout

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
