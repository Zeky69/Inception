FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Télécharger Portainer CE (détecte automatiquement l'architecture arm64/amd64)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -L "https://github.com/portainer/portainer/releases/download/2.21.0/portainer-2.21.0-linux-${ARCH}.tar.gz" \
    -o /tmp/portainer.tar.gz && \
    tar -xzf /tmp/portainer.tar.gz -C / && \
    rm /tmp/portainer.tar.gz

VOLUME ["/data"]

EXPOSE 9000

CMD ["/portainer/portainer", "--data=/data"]
