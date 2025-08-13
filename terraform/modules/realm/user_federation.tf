data "aws_ssm_parameter" "ldap_admin_password" {
  name = "/backstage/openldap/admin-password"
}

resource "keycloak_ldap_user_federation" "default" {
  realm_id = keycloak_realm.default.id
  name     = "openldap"
  enabled  = true

  connection_url  = "ldap://openldap:1389"
  bind_dn         = "cn=admin,dc=ldap,dc=bts-crew,dc=com"
  bind_credential = data.aws_ssm_parameter.ldap_admin_password.value

  edit_mode                 = "WRITABLE"
  users_dn                  = "dc=ldap,dc=bts-crew,dc=com"
  username_ldap_attribute   = "uid"
  rdn_ldap_attribute        = "uid"
  uuid_ldap_attribute       = "entryUUID"
  user_object_classes       = ["inetOrgPerson"]
  custom_user_search_filter = "(&(uid=*))"

  import_enabled           = true
  sync_registrations       = true
  validate_password_policy = true
  trust_email              = true

  cache {
    policy = "DEFAULT"
  }
}

resource "keycloak_ldap_user_attribute_mapper" "first_name_given_name" {
  realm_id                = keycloak_realm.default.id
  ldap_user_federation_id = keycloak_ldap_user_federation.default.id

  name                    = "firstName -> givenName"
  user_model_attribute    = "firstName"
  ldap_attribute          = "givenName"
  is_mandatory_in_ldap    = true
  attribute_force_default = true
}

resource "keycloak_ldap_user_attribute_mapper" "mobile" {
  realm_id                = keycloak_realm.default.id
  ldap_user_federation_id = keycloak_ldap_user_federation.default.id

  name                    = "Mobile number"
  user_model_attribute    = "mobile"
  ldap_attribute          = "mobile"
  attribute_force_default = true
}

resource "keycloak_ldap_user_attribute_mapper" "telephone_number" {
  realm_id                = keycloak_realm.default.id
  ldap_user_federation_id = keycloak_ldap_user_federation.default.id

  name                    = "Phone extension"
  user_model_attribute    = "extension"
  ldap_attribute          = "telephoneNumber"
  attribute_force_default = true
}
