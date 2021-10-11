FROM ubuntu:latest as artifact

ARG RADARR_VERSION=latest
ARG RADARR_BRANCH="develop"

RUN apt-get update && \
    apt-get install -y curl jq && \
    if [ "latest" != "$RADARR_VERSION" ];then VERSION=$RADARR_VERSION ; else VERSION=$(curl -sX GET "https://api.github.com/repos/Radarr/Radarr/releases" | jq -r '.[0] | .tag_name');fi && \
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/Radarr/Radarr/releases/tags/${VERSION}" | jq -r '.assets[].browser_download_url' |grep '\.linux\.tar\.gz') && \
    curl -L "${DOWNLOAD_URL}" | tar zxvf - && \
    mv Radarr* radarr && \
    curl -L "https://mediaarea.net/repo/deb/repo-mediaarea_1.0-13_all.deb" -o /radarr/mediaarea.deb && \
    chown -R 1001:0 /radarr && \
    chmod -R g=u /radarr

ADD test.sh /radarr/

RUN chmod 755 /radarr/test.sh && \
    chown 1001:0 /radarr/test.sh

FROM ubuntu:latest
LABEL maintainer='ParFlesh'

COPY --chown=1001:0 --from=artifact /radarr /radarr

ENV TZ=Etc/UTC \
    DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true 

RUN apt-get update && \
    apt-get install -y apt-transport-https gnupg gpgv2 ca-certificates && \
    UBUNTU_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release|awk -F'=' '{print $NF}') && \
    echo "deb https://mediaarea.net/repo/deb/ubuntu $UBUNTU_CODENAME main" | tee /etc/apt/sources.list.d/mediaarea.list && \
    dpkg -i /radarr/mediaarea.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests bzip2 ca-certificates-mono libcurl4-openssl-dev mediainfo mono-devel mono-vbnc python sqlite3 unzip && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/* && \
    echo "UpdateMethod=docker\nBranch=${RADARR_BRANCH}\nPackageVersion=${VERSION}\nPackageAuthor=ParFlesh" > /radarr/package_info && \
    rm -rf /radarr/bin/Radarr.Update && \
    mkdir /config && \
    chown 1001:0 /config && \
    chmod 770 /config

EXPOSE 7878
VOLUME ["/config"]
WORKDIR /radarr
ENTRYPOINT ["mono", "--debug", "Radarr.exe"]
CMD ["-nobrowser", "-data=/config"]
