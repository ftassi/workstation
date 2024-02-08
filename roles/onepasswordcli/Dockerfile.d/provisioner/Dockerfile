# See: https://github.com/mazgi/dockerfiles/blob/master/Dockerfile.d/provisioning/Dockerfile
FROM debian:10

# Set in non-interactive mode.
ENV DEBIAN_FRONTEND=noninteractive

ARG GID=0
ARG UID=0
ENV GID=${GID:-0}
ENV UID=${UID:-0}

ENV ANSIBLE_VERSION=2.9.12
ENV TERRAFORM_VERSION=0.12.9

RUN echo 'apt::install-recommends "false";' > /etc/apt/apt.conf.d/no-install-recommends\
  && apt-get update\
  # 
  # Set up locales
  && apt-get install --assume-yes locales procps dialog\
  && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen\
  && locale-gen\
  #
  # Install basic packages
  && apt-get install --assume-yes sudo apt-utils curl dnsutils git jq openssh-client tmux unzip zsh\
  && apt-get install --assume-yes apt-transport-https ca-certificates gnupg gnupg2 software-properties-common\
  # 
  # Install Docker CLI
  && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -\
  && add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian \
  $(lsb_release -cs) \
  stable"\
  && apt-get update\
  && apt-get install --assume-yes docker-ce-cli\
  # 
  # Install Google Cloud SDK
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -\
  && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main"\
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list\
  && apt-get update\
  && apt-get install --assume-yes google-cloud-sdk\
  # 
  # Install Terraform
  && curl -L -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip\
  && unzip -d /usr/local/bin/ /tmp/terraform.zip\
  #
  # Install Ansible
  && apt-get install --assume-yes python3-pip python3-setuptools\
  && pip3 install ansible==${ANSIBLE_VERSION} ansible-lint\
  # 
  # Create a user for development
  && addgroup --gid ${GID} developer || true\
  && adduser --disabled-password --uid ${UID} --gecos '' --gid ${GID} developer || true\
  && echo '%users ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/grant-all-without-password-to-users\
  && echo '%developer ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/grant-all-without-password-to-developer

# Reset DEBIAN_FRONTEND to default(`dialog`).
# If you no need `dialog`, you can set `DEBIAN_FRONTEND=readline`.
# see also: man 7 debconf
ENV DEBIAN_FRONTEND=
