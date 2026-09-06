FROM rockylinux:9

ENV LANG=C.UTF-8

RUN dnf install -y \
    ca-certificates \
    sudo \
    python3 \
    gnupg2 \
    lvm2 \
    e2fsprogs \
    xfsprogs \
    cloud-utils-growpart \
    util-linux \
    iproute \
    procps-ng \
  && dnf clean all \
  && rm -rf /var/cache/dnf

RUN useradd -m -s /bin/bash deploy \
  && echo 'deploy ALL=(ALL) ALL' >/etc/sudoers.d/deploy \
  && chmod 0440 /etc/sudoers.d/deploy

WORKDIR /workspace
CMD ["sleep", "infinity"]
