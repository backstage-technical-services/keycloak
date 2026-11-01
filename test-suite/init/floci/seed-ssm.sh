#!/bin/bash
# Floci READY hook: seed the SSM parameters read by the terraform/realms/* roots and modules.
# Mounted at /etc/floci/init/ready.d/ (requires floci/floci:*-compat image for `aws` CLI).
# https://floci.io/floci/configuration/initialization-hooks/

set -euo pipefail

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-eu-west-1}"

put_param() {
  aws ssm put-parameter \
    --name "$1" \
    --type String \
    --value "$2" \
    --overwrite \
    --region "$AWS_DEFAULT_REGION"
}

echo '[floci ready.d] Seeding SSM parameters...'

put_param '/backstage/keycloak/terraform-config' '{"clientId":"test","clientSecret":"test"}'
put_param '/backstage/keycloak/smtp-credentials' '{"username":"smtp-user-test","password":"smtp-pass-test"}'
put_param '/backstage/keycloak/idp/google-alumni' '{"clientId":"google-client-id-test","clientSecret":"google-client-secret-test"}'
put_param '/backstage/openldap/secrets' '{"adminPassword":"admin"}'

echo '[floci ready.d] SSM seed complete.'
