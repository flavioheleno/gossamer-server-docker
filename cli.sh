#!/usr/bin/env bash

# https://sipb.mit.edu/doc/safe-shell/
set -eufo pipefail

shopt -s failglob

docker run \
  --rm \
  --interactive \
  --tty \
  --network "$(docker network ls --quiet --filter name=gossamer-network$)" \
  --env POSTGRES_PASSWORD="$(cat ./secrets/postgres-passwd.txt)" \
  --env POSTGRES_USER="$(cat ./secrets/postgres-user.txt)" \
  --env POSTGRES_DB="$(cat ./secrets/postgres-db.txt)" \
  --volumes-from "$(docker ps --quiet --filter name=gossamer-[0-1]$)" \
  ghcr.io/flavioheleno/gossamer-server-cli:latest \
  sh
