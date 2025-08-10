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

FROM maven:3-eclipse-temurin-21 AS theme-builder

RUN apt-get update -y \
    && apt-get install -y \
      nodejs \
      npm \
    && npm install --global yarn

COPY theme /app/theme
WORKDIR /app/theme

RUN yarn install --frozen-lockfile \
    && yarn build:theme

FROM maven:3-eclipse-temurin-21 AS cas-builder

ARG KC_VERSION

RUN apt-get update -y \
    && apt-get install -y \
      git

WORKDIR /opt

RUN git clone https://github.com/RoboJackets/keycloak-cas.git \
    && cd keycloak-cas \
    && git checkout d397dfae68fc163d5e056378f434d7efdda8ed8f \
    && mvn package

FROM quay.io/keycloak/keycloak:${KC_VERSION} AS builder

ARG KC_VERSION

ADD --chown=keycloak:keycloak --chmod=644 \
  https://github.com/aerogear/keycloak-metrics-spi/releases/download/7.0.0/keycloak-metrics-spi-7.0.0.jar \
  /opt/keycloak/providers/keycloak-metrics-spi.jar
COPY --from=cas-builder --chown=keycloak:keycloak --chmod=644 \
  /opt/keycloak-cas/target/keycloak-cas-services-${KC_VERSION}-SNAPSHOT.jar \
  /opt/keycloak/providers/keycloak-cas-services.jar
ADD --chown=keycloak:keycloak --chmod=644 \
  https://github.com/sventorben/keycloak-restrict-client-auth/releases/download/v26.0.0/keycloak-restrict-client-auth.jar \
  /opt/keycloak/providers/keycloak-restrict-client-auth.jar
COPY --from=theme-builder --chown=keycloak:keycloak --chmod=644 \
  /app/theme/dist_keycloak/keycloak-theme-for-kc-all-other-versions.jar \
  /opt/keycloak/providers/keycloak-theme.jar

RUN /opt/keycloak/bin/kc.sh build \
    --health-enabled=true \
    --metrics-enabled=true \
    --features="docker,client-secret-rotation,admin-fine-grained-authz,opentelemetry,persistent-user-sessions" \
    --features-disabled="kerberos,multi-site" \
    --spi-restrict-client-auth-access-provider--client-role--enabled=true \
    --db=postgres

FROM quay.io/keycloak/keycloak:${KC_VERSION}

COPY --from=deps /mnt/rootfs /
COPY --from=builder /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD [ \
  "start", \
  "--optimized", \
  "--spi-restrict-client-auth-access-provider--client-role--enabled=true", \
  "--spi-restrict-client-auth-access-provider--client-role-client--role-name=client-access" \
]
