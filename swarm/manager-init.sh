#!/bin/bash

{{ source "common.ikt" }}

set -o errexit
set -o nounset
set -o xtrace

{{/* Install Docker */}}
{{ include "install-docker.sh" }}

{{/* Set up infrakit */}}
{{ include "infrakit.sh" }}

mkdir -p /etc/docker
cat << EOF > /etc/docker/daemon.json
{
  "labels": {{ INFRAKIT_LABELS | to_json }}
}
EOF

{{/* Reload the engine labels */}}
kill -s HUP $(cat /var/run/docker.pid)
sleep 5


{{ if and (eq INSTANCE_LOGICAL_ID SPEC.SwarmJoinIP) (not SWARM_INITIALIZED) }}

  {{/* The first node of the special allocations will initialize the swarm. */}}
  docker swarm init --advertise-addr {{ INSTANCE_LOGICAL_ID }}  # starts :2377

{{ else }}

  {{/* The rest of the nodes will join as followers in the manager group. */}}
  docker swarm join --token {{ SWARM_JOIN_TOKENS.Manager }} {{ SWARM_MANAGER_ADDR }}

{{ end }}

{{/* infrakit boot */}}
{{ include "boot.sh" }}

# Append commands here to run other things...
