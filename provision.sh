#!/usr/bin/env bash

apt-add-repository -y ppa:ansible/ansible
apt update -y
apt-get install -y software-properties-common
apt-get install -y ansible git
