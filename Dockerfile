FROM --platform=$BUILDPLATFORM node:18.9-alpine3.15 AS client-builder

WORKDIR /ui

# cache packages in layer
COPY ui/package.json /ui/package.json
COPY ui/package-lock.json /ui/package-lock.json

RUN --mount=type=cache,target=/usr/src/app/.npm \
    npm set cache /usr/src/app/.npm && \
    npm ci

# install
COPY ui /ui
RUN npm run build

FROM ubuntu:20.04
LABEL org.opencontainers.image.title="Pach extension" \
    org.opencontainers.image.description="One click Pachyderm install" \
    org.opencontainers.image.vendor="Nitin" \
    com.docker.desktop.extension.api.version=">= 0.3.0" \
    com.docker.extension.screenshots="" \
    com.docker.extension.detailed-description="" \
    com.docker.extension.publisher-url="" \
    com.docker.extension.additional-urls="" \
    com.docker.extension.changelog=""

FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install build-essential curl file git ruby-full locales --no-install-recommends -y && \
    rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -f UTF-8 en_US.UTF-8

RUN useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

USER linuxbrew
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"

USER root
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

RUN curl -L -o helm-linux-amd64.tar.gz https://get.helm.sh/helm-v3.10.2-linux-amd64.tar.gz \
    && mkdir /linux \
    && tar -zxvf helm-linux-amd64.tar.gz \
    && chmod +x linux-amd64/helm && mv linux-amd64/helm /linux

RUN curl -L -o helm-darwin-amd64.tar.gz https://get.helm.sh/helm-v3.10.2-darwin-amd64.tar.gz \
    && mkdir /darwin \
    && tar -zxvf helm-darwin-amd64.tar.gz \
    && chmod +x darwin-amd64/helm && mv darwin-amd64/helm /darwin

RUN curl -L -o helm-windows-amd64.tar.gz https://get.helm.sh/helm-v3.10.2-windows-amd64.tar.gz \
    && mkdir /windows \
    && tar -zxvf helm-windows-amd64.tar.gz \
    && chmod +x windows-amd64/helm.exe && mv windows-amd64/helm.exe /windows

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl \
    && cp /usr/local/bin/kubectl /linux/

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl" \
    && chmod +x ./kubectl && mv ./kubectl /darwin/

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/windows/amd64/kubectl.exe" \
    && chmod +x ./kubectl.exe && mv ./kubectl.exe /windows/

COPY metadata.json .
COPY docker.svg .
COPY --from=client-builder /ui/build ui

