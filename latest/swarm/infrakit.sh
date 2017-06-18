{{ source "common.ikt" }}

# Set up infrakit.  This assumes Docker has been installed

{{ $infrakitHome := var "/infrakit/home" }}
mkdir -p {{$infrakitHome}}/configs
mkdir -p {{$infrakitHome}}/logs
mkdir -p {{$infrakitHome}}/plugins

{{ $dockerImage := var "/infrakit/docker/image" }}
{{ $dockerMounts := var "/infrakit/docker/options/mount" }}
{{ $dockerEnvs := var "/infrakit/docker/options/env" }}

echo "alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'" >> /root/.bashrc

alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'

{{ $stackName := var "/cluster/name" }}

{{ $metadataExportUrl := var "/infrakit/metadata/configURL" }}
{{ $metadataImage := var "/infrakit/metadata/docker/image" }}
{{ $metadataCmd := (cat "metadata --name var --template-url" $metadataExportUrl "--stack" $stackName) }}

{{ $instanceImage := var "/infrakit/instance/docker/image" }}
{{ $instanceCmd := (cat "instance --log 5 --namespace-tags" (cat "infrakit.scope=" $stackName | nospace)) }}

{{ $groupsURL := cat (var "/infrakit/config/root") "/groups.json" | nospace }}


echo "Starting up infrakit"
docker run -d --restart always --name mux -p 24864:24864 \
       {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit util mux --log 5

echo "Starting up timer plugin"
docker run -d --restart always --name time \
       {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit-event-time

echo "Starting up manager"
docker run -d --restart always --name manager \
       {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit-manager --name group  --proxy-for-group group-stateless swarm

docker run -d --restart always --name group-stateless \
       {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit-group-default --poll-interval 5s --name group-stateless

docker run -d --restart always --name flavor-swarm \
       {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit-flavor-swarm --log 5

echo "Starting up instance plugin"
docker run -d --restart always --name instance-plugin \
       {{$dockerMounts}} {{$dockerEnvs}} {{$instanceImage}} {{$instanceCmd}}

echo "Starting up metadata plugin"
docker run -d --restart always --name metadata \
       {{$dockerMounts}} {{$dockerEnvs}} {{$metadataImage}} {{$metadataCmd}}


# Need a bit of time for the leader to discover itself
sleep 10

# Try to commit - this is idempotent but don't error out and stop the cloud init script!
echo "Commiting to infrakit $(docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit manager commit {{$groupsURL}})"
