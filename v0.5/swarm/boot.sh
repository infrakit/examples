#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

{{ source "common.ikt" }}


##### Set up volumes ############################################################
# Only for managers
{{ if not (var "/local/infrakit/role/worker") }} {{ include "setup-volume.sh" }} {{ end }}

##### Set up Docker #############################################################

{{/* Install Docker */}}{{ if var "/local/install/docker" }} {{ include "install-docker.sh" }} {{ end }}

{{/* Label the Docker Engine */}}
{{ $dockerLabels := var "/local/docker/engine/labels" }}
{{ if not (eq 0 (len $dockerLabels)) }}
mkdir -p /etc/docker
cat << EOF > /etc/docker/daemon.json
{
  "labels": {{ $dockerLabels | jsonEncode }}
}
EOF
kill -s HUP $(cat /var/run/docker.pid)  {{/* Reload the engine labels */}}
sleep 5
{{ end }}

##### Set up Docker Swarm Mode  ##################################################

{{ if not (var "/cluster/swarm/initialized") }}
docker swarm init --advertise-addr {{ var "/cluster/swarm/join/ip" }}  # starts :2377
{{ end }}

##### Infrakit Services  #########################################################

{{ if not (var "/local/infrakit/role/worker") }}
{{ include "infrakit.sh" }}
{{ end }}{{/* if running infrakit */}}

##### Joining Swarm  #############################################################
{{ if var "/cluster/swarm/initialized" }}
sleep 5
echo "Joining swarm"
docker swarm join --token {{ var "/local/docker/swarm/join/token" }} {{ var "/local/docker/swarm/join/addr" }}
{{ end }}
