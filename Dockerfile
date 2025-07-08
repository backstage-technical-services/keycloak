ARG KC_VERSION="26.3.0"

FROM registry.access.redhat.com/ubi9 AS deps

RUN mkdir -p /mnt/rootfs
RUN dnf install \
    --installroot /mnt/rootfs \
    --releasever 9 \
    --setopt install_weak_deps=false \
    --nodocs \
    -y \
      curl \
      jq

RUN dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

FROM quay.io/keycloak/keycloak:${KC_VERSION} AS builder

ADD --chown=keycloak:keycloak --chmod=644 \
  https://github.com/aerogear/keycloak-metrics-spi/releases/download/7.0.0/keycloak-metrics-spi-7.0.0.jar \
  /opt/keycloak/providers/keycloak-metrics-spi.jar
ADD --chown=keycloak:keycloak --chmod=644 \
  https://github.com/jacekkow/keycloak-protocol-cas/releases/download/26.3.0/keycloak-protocol-cas-26.3.0.jar \
  /opt/keycloak/providers/keycloak-protocol-cas.jar
ADD --chown=keycloak:keycloak --chmod=644 \
  https://github.com/sventorben/keycloak-restrict-client-auth/releases/download/v26.0.0/keycloak-restrict-client-auth.jar \
  /opt/keycloak/providers/keycloak-restrict-client-auth.jar
COPY --chown=keycloak:keycloak --chmod=644 \
  theme/dist_keycloak/keycloak-theme-for-kc-all-other-versions.jar \
  /opt/keycloak/providers/keycloak-theme.jar

RUN /opt/keycloak/bin/kc.sh build \
    --health-enabled=true \
    --metrics-enabled=true \
    --features="docker,client-secret-rotation,admin-fine-grained-authz,opentelemetry,persistent-user-sessions" \
    --features-disabled="kerberos,multi-site" \
    --spi-restrict-client-auth-access-provider-client-role-enabled=true \
    --spi-restrict-client-auth-access-provider-client-role-client-role-name=client-access \
    --db=postgres

FROM quay.io/keycloak/keycloak:${KC_VERSION}

COPY --from=deps /mnt/rootfs /
COPY --from=builder /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD [ \
  "start", \
  "--optimized", \
  "--spi-restrict-client-auth-access-provider-client-role-enabled=true", \
  "--spi-restrict-client-auth-access-provider-client-role-client-role-name=client-access" \
]
