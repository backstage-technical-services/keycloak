# Backstage Keycloak

The Keycloak image (with the BTS login theme and extensions), its Helm chart, and the Terraform that configures the
`prod` and `nonprod` realms.

## Managing Issues
[Issues and features should be made atomic into an issue, and the lifecycles of said issues should be tracked with the project tracker.](https://github.com/orgs/backstage-technical-services/projects/7/)

## Configuring a realm

Each realm is configured by a YAML file in [`realms/`](realms):

| Realm     | Config                                     | Terraform root                                     |
|-----------|--------------------------------------------|----------------------------------------------------|
| `prod`    | [`realms/prod.yaml`](realms/prod.yaml)       | [`terraform/realms/prod`](terraform/realms/prod)       |
| `nonprod` | [`realms/nonprod.yaml`](realms/nonprod.yaml) | [`terraform/realms/nonprod`](terraform/realms/nonprod) |

The realms are configured independently, so a change to one realm's file doesn't affect the other. The files are
validated against [`schemas/realm.json`](schemas/realm.json), which editors with YAML language support will pick up
for autocompletion and inline docs.

Opening a pull request plans the affected realms and posts the plan as a comment; merging it applies them. This needs
AWS access, so pull requests must come from a branch in this repository rather than a fork.

### Adding a client

```yaml
clients:
  - name: my-app                 # the client ID
    display-name: My App
    access-mode: restricted      # optional; see below
    auth-flows:
      standard: true             # authorization code
      client-credentials: true   # enables the service account
    redirect-urls:
      - https://my-app.bts-crew.com/*
    logout-redirect-urls:
      - https://my-app.bts-crew.com/*
    roles:                       # optional client roles
      - name: admin
    service-account-roles:       # optional; requires client-credentials
      - client: realm-management
        name: view-users
```

`access-mode` controls who can log in to the client:

- `open` (the default): anyone with an account.
- `restricted`: only users who have the client's `client-access` role.
- the name of a group in the same file: as `restricted`, and members of that group are given `client-access`.

### Adding a group

```yaml
groups:
  - name: My Group
    roles:
      - client: my-app           # a client in this file, or eg realm-management
        name: admin
```

### Realm-specific Terraform

Anything that can't be expressed in the YAML can be added as Terraform alongside the `module "realm"` call in the
realm's root. The module outputs the realm `id`, the `clients` (IDs and role IDs) and the `groups` (IDs).

To run Terraform locally (requires the `backstage` AWS profile):

```bash
terraform -chdir=terraform/realms/nonprod init
terraform -chdir=terraform/realms/nonprod plan
```

## Tests

The [E2E test suite](test-suite) builds the Keycloak image, runs it with Postgres, OpenLDAP, MailDev and an SSM
emulator, applies every realm root to it, then checks the result with Vitest. It runs on pull requests that change the
image or the Terraform.

```bash
yarn --cwd test-suite install
yarn --cwd test-suite setup
yarn --cwd test-suite test
yarn --cwd test-suite cleanup
```

## Running locally

```bash
docker compose up
```

Keycloak is available at http://localhost:8081 (admin/admin).
