# The released WSO2 Integration Control Plane, checked against its published SHA-256. The zip is downloaded from the
# GitHub release; to skip the download (slow or flaky networks), put the release zip and its .sha256 next to this file.
FROM eclipse-temurin:25-jre
ARG ICP_VERSION=2.1.0
RUN apt-get update && apt-get install -y --no-install-recommends unzip curl && rm -rf /var/lib/apt/lists/*
COPY . /ctx
RUN set -eu; \
    name="wso2-integration-control-plane-${ICP_VERSION}"; \
    url="https://github.com/wso2/integration-control-plane/releases/download/v${ICP_VERSION}/${name}.zip"; \
    cd /tmp; \
    if [ -f "/ctx/${name}.zip" ]; then cp "/ctx/${name}.zip" icp.zip; \
    else curl -fsSL --retry 10 --retry-all-errors --retry-delay 5 -C - -o icp.zip "$url"; fi; \
    if [ -f "/ctx/${name}.zip.sha256" ]; then cp "/ctx/${name}.zip.sha256" icp.zip.sha256; \
    else curl -fsSL --retry 10 --retry-all-errors -o icp.zip.sha256 "$url.sha256"; fi; \
    echo "$(cut -d' ' -f1 icp.zip.sha256)  icp.zip" | sha256sum -c -; \
    unzip -q icp.zip -d /opt; mv "/opt/${name}" /opt/icp; \
    rm -rf icp.zip icp.zip.sha256 /ctx; chmod +x /opt/icp/bin/icp.sh
COPY deployment.toml /opt/icp/conf/deployment.toml
EXPOSE 9445 9446
WORKDIR /opt/icp
# In the foreground, so Docker owns the process (bin/icp.sh start would daemonise and exit).
ENTRYPOINT ["/opt/icp/bin/icp.sh", "run"]
