data "aws_ssm_parameter" "openldap_secrets" {
  name = "/backstage/openldap/secrets"
}

resource "keycloak_ldap_user_federation" "default" {
  realm_id = keycloak_realm.default.id
  name     = "openldap"
  enabled  = true

  connection_url  = "ldap://openldap:1389"
  bind_dn         = "cn=admin,dc=ldap,dc=bts-crew,dc=com"
  bind_credential = jsondecode(data.aws_ssm_parameter.openldap_secrets.value)["adminPassword"]

  edit_mode                 = var.federation_readonly ? "READ_ONLY" : "WRITABLE"
  users_dn                  = "ou=users,dc=ldap,dc=bts-crew,dc=com"
  username_ldap_attribute   = "uid"
  rdn_ldap_attribute        = "uid"
  uuid_ldap_attribute       = "entryUUID"
  user_object_classes       = ["inetOrgPerson"]
  custom_user_search_filter = "(&(uid=*))"
  search_scope              = "SUBTREE"

  import_enabled           = true
  sync_registrations       = true
  validate_password_policy = !var.federation_readonly
  trust_email              = true

  cache {
    policy = "DEFAULT"
  }
}

resource "keycloak_group" "ldap" {
  realm_id = keycloak_realm.default.id
  name     = "LDAP"
}

resource "keycloak_ldap_group_mapper" "default" {
  realm_id                = keycloak_realm.default.id
  ldap_user_federation_id = keycloak_ldap_user_federation.default.id

  name                           = "group-mapper"
  ldap_groups_dn                 = "ou=groups,dc=ldap,dc=bts-crew,dc=com"
  group_name_ldap_attribute      = "cn"
  group_object_classes           = ["posixGroup"]
  membership_ldap_attribute      = "memberUid"
  membership_attribute_type      = "UID"
  membership_user_ldap_attribute = "uid"
  mode                           = var.federation_readonly ? "READ_ONLY" : "LDAP_ONLY"
  memberof_ldap_attribute        = "memberOf"
  mapped_group_attributes        = ["gidNumber"]

  preserve_group_inheritance           = false
  drop_non_existing_groups_during_sync = !var.federation_readonly
  groups_path                          = "/${keycloak_group.ldap.name}"
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
