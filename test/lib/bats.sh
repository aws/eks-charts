#!/usr/bin/env bash

# Install Bash Automated Testing System

set -o errexit

export REPO_ROOT=$(git rev-parse --show-toplevel)
BATS_VERSION=1.1.0

if [[ "$1" ]]; then
  BATS_VERSION=$1
fi

function installBats() {
  cd /tmp
  curl -sSL https://github.com/bats-core/bats-core/archive/v${BATS_VERSION}.tar.gz -o bats.tar.gz
  tar -xvf bats.tar.gz --strip 1
}

installBats