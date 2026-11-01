FROM scratch

# Filled in by the workflow from the upstream download feed.
ARG FRPC_VERSION=unknown
ARG SOURCE=https://github.com/zetxtech/chmlfrp-docker

LABEL org.opencontainers.image.title="chmlfrp" \
      org.opencontainers.image.description="ChmlFrp frpc client, packaged like the frpc Docker image (/usr/bin/frpc, -c /etc/frp/frpc.toml)" \
      org.opencontainers.image.version="${FRPC_VERSION}" \
      org.opencontainers.image.source="${SOURCE}" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY dist/frpc /usr/bin/frpc
COPY cacert.pem /etc/ssl/certs/ca-certificates.crt

# The upstream client is a static Go binary, so scratch works for every
# platform chmlfrp publishes, including mips* and riscv64 where no base
# image exists and no emulation is needed to assemble the layer.
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

WORKDIR /etc/frp

ENTRYPOINT ["/usr/bin/frpc"]
CMD ["-c", "/etc/frp/frpc.toml"]
