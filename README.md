# Keycloak ![Deploy](https://github.com/backstage-technical-services/keycloak/workflows/Deploy/badge.svg)

[Keycloak][keycloak] is an open-source identity and access management solution, developed by JBoss and is one of the industry standard solutions for OAuth 2.0 and OpenID Connect (OIDC) authentication and authorisation.

As part of the move to a separate API and SPA, the BTS site is moving to a new framework: Quarkus. This framework follows the [MicroProfile][microprofile] spec developed by Eclipse, and so does not include its own authentication and authorisation method that supports OIDC; instead it delegates this to an OIDC provider and has an adapter to enable integration with Keycloak.

Unfortunately, no one currently offers managed Keycloak hosting and so we need to host it ourselves. This repository holds the configuration needed to provision an Ubuntu-based server and manage an installation of Keycloak using Docker. There are 3 parts:

* A PostgreSQL database
* Keycloak (self-configures and contains a Tomcat server)
* nginx (to terminate TLS and proxy to Keycloak)

[keycloak]: https://www.keycloak.org/
[microprofile]: https://projects.eclipse.org/projects/technology.microprofile
