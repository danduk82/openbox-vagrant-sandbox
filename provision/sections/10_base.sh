#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  apt-transport-https \
  bash-completion \
  build-essential \
  ca-certificates \
  curl \
  git \
  gnupg \
  jq \
  lsb-release \
  make \
  openjdk-17-jdk-headless \
  python3 \
  python3-pip \
  python3-venv \
  python3-wheel \
  software-properties-common \
  unzip \
  vim \
  xauth \
  xclip \
  zip
