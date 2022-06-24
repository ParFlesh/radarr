FROM ubuntu:focal as artifact

ARG RADARR_VERSION=latest
ARG RADARR_BRANCH="develop"

RUN apt-get update && \
    apt-get install -y curl jq && \
    if [ "latest" != "$RADARR_VERSION" ];then VERSION=$RADARR_VERSION ; else VERSION=$(curl -sX GET "https://api.github.com/repos/Radarr/Radarr/releases" | jq -r '.[0] | .tag_name');fi && \
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/Radarr/Radarr/releases/tags/${VERSION}" | jq -r '.assets[].browser_download_url' |grep '\.linux-core-x64\.tar\.gz') && \
    curl -L "${DOWNLOAD_URL}" | tar zxvf - && \
    mv Radarr* radarr && \
    rm -rf /radarr/bin/Radarr.Update && \
    curl -o /radarr/repo-mediaarea.deb https://mediaarea.net/repo/deb/repo-mediaarea_1.0-19_all.deb && \
    chown -R 1001:0 /radarr && \
    chmod -R g=u /radarr

ADD test.sh /radarr/

RUN chmod 755 /radarr/test.sh && \
    chown 1001:0 /radarr/test.sh

FROM ubuntu:focal
LABEL maintainer='ParFlesh'

COPY --chown=1001:0 --from=artifact /radarr /radarr

ENV TZ=Etc/UTC \
    DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true 

RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates && \
    dpkg -i /radarr/repo-mediaarea.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests mediainfo sqlite3 unzip libicu66 && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/* && \
    echo "UpdateMethod=docker\nBranch=${RADARR_BRANCH}\nPackageVersion=${VERSION}\nPackageAuthor=ParFlesh" > /radarr/package_info && \
    mkdir /config && \
    chown 1001:0 /config && \
    chmod 770 /config

EXPOSE 7878
VOLUME ["/config"]
WORKDIR /radarr
ENTRYPOINT ["/radarr/Radarr"]
CMD ["-nobrowser", "-data=/config"]
