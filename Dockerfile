FROM --platform=$TARGETPLATFORM node:18.9-alpine3.15 AS client-builder

WORKDIR /ui

# cache packages in layer
COPY ui/package.json /ui/package.json
COPY ui/package-lock.json /ui/package-lock.json

RUN --mount=type=cache,target=/usr/src/app/.npm \
    npm set cache /usr/src/app/.npm && \
    npm ci

# install
COPY ui /ui
RUN npx update-browserslist-db@latest
RUN npm run build

FROM --platform=$TARGETPLATFORM alpine
ARG TARGETARCH

LABEL org.opencontainers.image.title="Pachyderm" \
    org.opencontainers.image.description="Automate data transformation with data versioning and lineage -- Any data, Any scale, Any Language" \
    com.docker.desktop.extension.icon="https://raw.githubusercontent.com/pachyderm/pachyderm/master/Pachyderm_Icon-01.svg" \
    org.opencontainers.image.vendor="Pachyderm" \
    com.docker.desktop.extension.api.version=">= 0.3.0" \
    com.docker.extension.screenshots="" \
    com.docker.extension.detailed-description=' \
        <p> \
	    <h1 style="text-align: center">What is Pachyderm?</h1> \
		<p>Pachyderm is cost-effective at scale and enables data engineering teams to automate complex pipelines with sophisticated data transformations. \
		</p> \
		<div style="text-align: center"> \
		<img width="723" height="450" src="https://www.pachyderm.com/wp-content/uploads/2022/07/pachyderm-platform-0722-v02.svg" srcset="" sizes=""/> \
		</div> \
	    <h1 style="text-align: center">Key Benefits?</h1> \
		<ul> \
		    <li>Data-driven pipelines automatically trigger based on detecting data changes.</li> \
		    <li>Immutable data lineage with data versioning of any data type.</il> \
		    <li>Autoscaling and parallel processing built on Kubernetes for resource orchestration.</il> \
		    <li>Uses standard object stores for data storage with automatic deduplication.</il> \
		    <li>Runs across all major cloud providers and on-premises installations.</il> \
		</ul> \
	</p>' \
    com.docker.extension.publisher-url="https://pachyderm.com" \
    com.docker.extension.additional-urls='[ \
	{"title":"Get Started","url":"https://docs.pachyderm.com/2.4.x/getting-started/beginner-tutorial/"}, \
	{"title":"Examples","url":"https://www.pachyderm.com/resources/type/examples/"}, \
	{"title":"Video & Image processing","url":"https://www.pachyderm.com/solutions/unstructured-data/"}, \
	{"title":"MLOps","url":"https://www.pachyderm.com/solutions/mlops/"}, \
	{"title":"Data-Centric AI","url":"https://www.pachyderm.com/data-centric-ai/"}, \
	{"title":"Documentation","url":"https://docs.pachyderm.com/"}, \
	{"title":"GitHub","url":"https://github.com/pachyderm/pachyderm"}, \
        {"title":"Website","url":"https://pachyderm.com/"} \
	]'

RUN apk add curl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl \
    && mkdir /linux \
    && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl \
    && cp /usr/local/bin/kubectl /linux/

RUN curl -L -o helm-linux-${TARGETARCH}.tar.gz https://get.helm.sh/helm-v3.10.2-linux-${TARGETARCH}.tar.gz \
    && tar -zxvf helm-linux-${TARGETARCH}.tar.gz \
    && chmod +x linux-${TARGETARCH}/helm && mv linux-${TARGETARCH}/helm /linux

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/${TARGETARCH}/kubectl" \
    && mkdir /darwin \
    && chmod +x ./kubectl && mv ./kubectl /darwin/

RUN curl -L -o helm-darwin-${TARGETARCH}.tar.gz https://get.helm.sh/helm-v3.10.2-darwin-${TARGETARCH}.tar.gz \
    && tar -zxvf helm-darwin-${TARGETARCH}.tar.gz \
    && chmod +x darwin-${TARGETARCH}/helm && mv darwin-${TARGETARCH}/helm /darwin

RUN if [ "${TARGETARCH}" = "amd64" ]; then \
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/windows/${TARGETARCH}/kubectl.exe" \
        && mkdir /windows \
        && chmod +x ./kubectl.exe && mv ./kubectl.exe /windows/; \
    fi

RUN if [ "${TARGETARCH}" = "amd64" ]; then \
        curl -L -o helm-windows-${TARGETARCH}.tar.gz https://get.helm.sh/helm-v3.10.2-windows-${TARGETARCH}.tar.gz \
        && tar -zxvf helm-windows-${TARGETARCH}.tar.gz \
        && chmod +x windows-${TARGETARCH}/helm.exe && mv windows-${TARGETARCH}/helm.exe /windows; \
    fi

COPY --chmod=0755 script/run.sh /darwin/run.sh
COPY --chmod=0755 script/run.sh /linux/run.sh
COPY --chmod=0755 script/run.ps1 /windows/run.ps1

COPY metadata.json .
COPY pachydermLogoFooter.svg .
COPY --from=client-builder /ui/build ui
