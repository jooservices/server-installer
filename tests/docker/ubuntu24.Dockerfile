FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    sudo \
    python3 \
    gnupg \
    lvm2 \
    e2fsprogs \
    xfsprogs \
    cloud-guest-utils \
    util-linux \
    iproute2 \
    procps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Non-root operator used by sudo_nopass / docker_group checks.
RUN useradd -m -s /bin/bash deploy \
  && echo 'deploy ALL=(ALL) ALL' >/etc/sudoers.d/deploy \
  && chmod 0440 /etc/sudoers.d/deploy

WORKDIR /workspace
CMD ["sleep", "infinity"]
