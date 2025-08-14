locals {
  default_tags = {
    managed-by = "Terraform"
    owner      = "backstage"
    repo       = "backstage/keycloak"
    realm      = try(regex("[^/]+$", path.cwd), "unknown")
  }
}


module "realm" {
  source = "../../modules/realm"

  name         = "nonprod"
  display_name = "Backstage (NonProd)"

  access_token_lifespan = "8h"
}
