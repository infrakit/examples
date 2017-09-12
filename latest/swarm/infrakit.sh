{{ source "common.ikt" }}

# Set up infrakit.  This assumes Docker has been installed

{{ $infrakitHome := var "/infrakit" }}
mkdir -p {{$infrakitHome}}/configs
mkdir -p {{$infrakitHome}}/logs
mkdir -p {{$infrakitHome}}/plugins

{{ $dockerImage := var "/infrakit/docker/image" }}
{{ $dockerMounts := `-v /var/run/docker.sock:/var/run/docker.sock -v /infrakit:/infrakit`}}
{{ $dockerEnvs := `-e INFRAKIT_HOME=/infrakit -e INFRAKIT_PLUGINS_DIR=/infrakit/plugins`}}


echo "alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'" >> /root/.bashrc

alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'

{{ $groupsURL := cat (var "/infrakit/config/root") "/groups.json" | nospace }}

echo "Starting up infrakit"
docker run -d --restart always --name infrakit -p 24864:24864 {{ $dockerMounts }} {{ $dockerEnvs }} \
       -e INFRAKIT_MANAGER_BACKEND=swarm \
       -e INFRAKIT_AWS_STACKNAME={{ var `/cluster/name` }} \
       -e INFRAKIT_AWS_METADATA_TEMPLATE_URL={{ var `/infrakit/metadata/configURL` }} \
       -e INFRAKIT_TAILER_PATH=/infrakit/logs/infrakit.log
       {{$dockerImage}} \
       infrakit plugin start manager group aws swarm ingress time --log 5 > /infrakit/logs/infrakit.log

# Need a bit of time for the leader to discover itself
sleep 10

# Try to commit - this is idempotent but don't error out and stop the cloud init script!
echo "Commiting to infrakit $(infrakit manager commit {{$groupsURL}})"
