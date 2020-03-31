#!/bin/bash
set -x

if [ -e /etc/redhat-release ] ; then
  REDHAT_BASED=true
fi

TERRAFORM_VERSION="0.12.24"
PACKER_VERSION="1.5.5"
DOCKER_COMPOSE_VERSION="1.25.4"
DOCKER_MACHINE_VERSION="0.16.2"
# create new ssh key
[[ ! -f /home/ubuntu/.ssh/mykey ]] \
&& mkdir -p /home/ubuntu/.ssh \
&& ssh-keygen -f /home/ubuntu/.ssh/mykey -N '' \
&& chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# install packages
if [ ${REDHAT_BASED} ] ; then
  yum -y update
  yum -y install epel-release
  yum -y update
  yum install -y docker ansible unzip wget
else 
  apt-get update
  #apt-get -y install docker.io ansible unzip
  apt-get -y install unzip apt-transport-https ca-certificates curl software-properties-common
  # install ansible from repo
  apt-add-repository ppa:ansible/ansible
  apt-get update && apt-get -y install ansible
  # install docker from repo
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  . /etc/lsb-release
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $DISTRIB_CODENAME stable"
  apt-get update
  apt-get -y install docker-ce
fi

# add docker privileges
usermod -G docker ubuntu
usermod -G docker vagrant

# install pip
pip install -U pip && pip3 install -U pip
if [[ $? == 127 ]]; then
    wget -q https://bootstrap.pypa.io/get-pip.py
    python get-pip.py
    python3 get-pip.py
fi
# install awscli and ebcli
pip install -U awscli
pip install -U awsebcli

#terraform
T_VERSION=$(/usr/local/bin/terraform -v | head -1 | cut -d ' ' -f 2 | tail -c +2)
T_RETVAL=${PIPESTATUS[0]}

[[ $T_VERSION != $TERRAFORM_VERSION ]] || [[ $T_RETVAL != 0 ]] \
&& wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
&& unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
&& rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# packer
P_VERSION=$(/usr/local/bin/packer -v)
P_RETVAL=$?

[[ $P_VERSION != $PACKER_VERSION ]] || [[ $P_RETVAL != 1 ]] \
&& wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
&& unzip -o packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/local/bin \
&& rm packer_${PACKER_VERSION}_linux_amd64.zip

# install docker-compose and docker-machine
# docker-compose
DC_VERSION=$(docker-compose --version | cut -f1 -d, | cut -f3 -d' ')
DC_RETVAL=${PIPESTATUS[0]}
[[ $DC_VERSION != $DOCKER_COMPOSE_VERSION ]] || [[ $DC_RETVAL != 0 ]] \
&& curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose \
&& chmod +x /usr/local/bin/docker-compose 

# docker-machine
DM_VERSION=$(docker-machine --version | cut -f1 -d, | cut -f3 -d' ')
DM_RETVAL=${PIPESTATUS[0]}
[[ $DM_VERSION != $DOCKER_MACHINE_VERSION ]] || [[ $DM_RETVAL != 0 ]] \
&& curl -L https://github.com/docker/machine/releases/download/v$DOCKER_MACHINE_VERSION/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine \
&& chmod +x /tmp/docker-machine \
&& mv /tmp/docker-machine /usr/local/bin/docker-machine

# clean up
if [ ! ${REDHAT_BASED} ] ; then
  apt-get clean
fi

