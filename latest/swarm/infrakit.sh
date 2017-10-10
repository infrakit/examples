{{ source "common.ikt" }}
echo # Set up infrakit.  This assumes Docker has been installed
{{ $infrakitHome := `/infrakit` }}
mkdir -p {{$infrakitHome}}/configs
mkdir -p {{$infrakitHome}}/logs
mkdir -p {{$infrakitHome}}/plugins

# dockerImage  {{ $dockerImage := var "/infrakit/docker/image" }}
# dockerMounts {{ $dockerMounts := `-v /var/run/docker.sock:/var/run/docker.sock -v /infrakit:/infrakit` }}
# dockerEnvs   {{ $dockerEnvs := `-e INFRAKIT_HOME=/infrakit -e INFRAKIT_PLUGINS_DIR=/infrakit/plugins`}}


# Cluster {{ var `/cluster/name` }} size is {{ var `/cluster/size` }}

echo "Cluster {{ var `/cluster/name` }} size is {{ var `/cluster/swarm/size` }}"
echo "alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'" >> /root/.bashrc

alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'

echo "Starting up infrakit  ######################"
docker run -d --restart always --name infrakit -p 24864:24864 {{ $dockerMounts }} {{ $dockerEnvs }} \
       -v /var/log/:/var/log \
       -e INFRAKIT_AWS_STACKNAME={{ var `/cluster/name` }} \
       -e INFRAKIT_AWS_METADATA_POLL_INTERVAL=300s \
       -e INFRAKIT_AWS_METADATA_TEMPLATE_URL={{ var `/infrakit/metadata/configURL` }} \
       -e INFRAKIT_AWS_NAMESPACE_TAGS=infrakit.scope={{ var `/cluster/name` }} \
       -e INFRAKIT_MANAGER_BACKEND=swarm \
       -e INFRAKIT_ADVERTISE={{ var `/local/swarm/manager/logicalID` }}:24864 \
       -e INFRAKIT_TAILER_PATH=/var/log/cloud-init-output.log \
       {{$dockerImage}} \
       infrakit plugin start manager group vars aws combo swarm time tailer ingress \
       --log 5 --log-debug-V 900

# Need a bit of time for the leader to discover itself
sleep 60

echo "Update the vars in the metadata plugin -- we put this in the vars plugin for queries later."
docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit vars metadata change -c \
       cluster/name={{ var `/cluster/name` }} \
       cluster/size={{ var `/cluster/size` }} \
       infrakit/config/root={{ var `/infrakit/config/root` }} \
       infrakit/docker/image={{ var `/infrakit/docker/image` }} \
       provider/image/hasDocker={{ var `/provider/image/hasDocker` }} \


echo "Rendering a view of the config groups.json for debugging."
docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit template {{var `/infrakit/config/root`}}/groups.json

#Try to commit - this is idempotent but don't error out and stop the cloud init script!
echo "Commiting to infrakit $(docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit manager commit {{var `/infrakit/config/root`}}/groups.json)"
