#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

{{ source "common.ikt" }}


##### Set up volumes ############################################################
# Only for managers
{{ if not (ref "/local/infrakit/role/worker") }} {{ include "setup-volume.sh" }} {{ end }}

##### Set up Docker #############################################################

{{/* Install Docker */}}{{ if ref "/local/install/docker" }} {{ include "install-docker.sh" }} {{ end }}

{{/* Label the Docker Engine */}}
{{ $dockerLabels := ref "/local/docker/engine/labels" }}
{{ if not (eq 0 (len $dockerLabels)) }}
mkdir -p /etc/docker
cat << EOF > /etc/docker/daemon.json
{
  "labels": {{ $dockerLabels | to_json }}
}
EOF
kill -s HUP $(cat /var/run/docker.pid)  {{/* Reload the engine labels */}}
sleep 5
{{ end }}

##### Set up Docker Swarm Mode  ##################################################

{{ if not (ref "/cluster/swarm/initialized") }}
docker swarm init --advertise-addr {{ ref "/cluster/swarm/join/ip" }}  # starts :2377
{{ end }}


##### Infrakit Services  #########################################################

{{ if not (ref "/local/infrakit/role/worker") }}
{{ include "infrakit.sh" }}
{{ end }}{{/* if running infrakit */}}

{{ if ref "/cluster/swarm/initialized" }}


##### Joining Swarm  #############################################################
sleep 5
echo "Joining swarm"
docker swarm join --token {{ ref "/local/docker/swarm/join/token" }} {{ ref "/local/docker/swarm/join/addr" }}
{{ end }}
