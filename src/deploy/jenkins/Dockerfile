FROM bitnami/kubectl:1.26.4 as kubectl
FROM docker:18.05-dind

ENV HELM_VERSION="v3.11.3"

RUN apk add --update ca-certificates git wget make bash \
 && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
 && tar -xvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
 && mv linux-amd64/helm /usr/local/bin \
 && rm -rf /helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64 \
 && addgroup -g 1000 -S helm \
 && adduser -u 1000 -h /home/helm -D -S -G helm helm \
 && rm /var/cache/apk/*

COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/

USER root