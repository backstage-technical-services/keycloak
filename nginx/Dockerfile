ARG VERSION

FROM nginx:$VERSION

RUN rm -rf /etc/nginx/sites-enabled && \
    rm -rf /etc/nginx/sites-available && \
    rm -rf /etc/nginx/conf.d && \
    mkdir /etc/nginx/sites-enabled && \
    mkdir /etc/nginx/sites-available

COPY nginx.conf /etc/nginx
COPY sites/* /etc/nginx/sites-available
RUN ln -s /etc/nginx/sites-available/keycloak.conf /etc/nginx/sites-enabled/

EXPOSE 443
VOLUME /etc/letsencrypt

CMD ["nginx", "-g", "daemon off;"]
