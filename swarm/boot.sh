#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

{{ source "common.ikt" }}


##### Set up volumes ############################################################

{{ if ref "/local/instance/volume/attach" }}{{ include "setup-volume.sh" }} {{ end }}

##### Set up Docker #############################################################

{{/* Install Docker */}}{{ if ref "/local/install/docker" }} {{ include "install-docker.sh" }} {{ end }}

{{/* Label the Docker Engine */}}
{{ $dockerLabels := ref "/local/docker/engine/labels" }}
mkdir -p /etc/docker
cat << EOF > /etc/docker/daemon.json
{
  "labels": {{ $dockerLabels | to_json }}
}
EOF
kill -s HUP $(cat /var/run/docker.pid)  {{/* Reload the engine labels */}}
sleep 5

##### Set up Docker Swarm Mode  ##################################################

{{ if not (ref "/cluster/swarm/initialized") }}
  docker swarm init --advertise-addr {{ ref "/cluster/swarm/join/ip" }}  # starts :2377
{{ else }}
  docker swarm join --token {{ ref "/local/docker/swarm/join/token" }} {{ ref "/local/docker/swarm/join/addr" }}
{{ end }}


##### Infrakit Services  #########################################################

{{ if not (ref "/local/infrakit/role/worker") }}

{{ include "infrakit.sh" }}

{{ $dockerImage := ref "/infrakit/docker/image" }}
{{ $dockerMounts := ref "/infrakit/docker/options/mount" }}
{{ $dockerEnvs := ref "/infrakit/docker/options/env" }}
{{ $pluginsURL := cat (ref "/cluster/config/urlRoot") "/plugins.json" | nospace }}
{{ $groupsURL := cat (ref "/cluster/config/urlRoot") "/groups.json" | nospace }}

{{ $instanceImage := ref "/infrakit/instance/docker/image" }}
{{ $instanceCmd := ref "/infrakit/instance/docker/cmd" }}

echo "Starting up infrakit"

docker run -d --name infrakit {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit plugin start --wait --config-url {{$pluginsURL}} --exec os --log 5 \
       manager \
       group-stateless \
       flavor-swarm

echo "Starting up instance-aws plugin"
docker run -d --name instance-plugin {{$dockerMounts}} {{$dockerEnvs}} {{$instanceImage}} {{$instanceCmd}}

# Need a bit of time for the leader to discover itself
sleep 10

echo "Commiting to infrakit"
docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit manager commit {{$groupsURL}}

{{ end }}{{/* if running infrakit */}}
