#!/bin/sh
set -e
mv /infratest/* /infrakit/
sed -i 's/docker run/docker container run/' /infrakit/swarm/infrakit.sh

eval "$@"
