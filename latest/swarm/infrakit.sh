{{ source "common.ikt" }}
echo # Set up infrakit.  This assumes Docker has been installed
{{ $infrakitHome := `/infrakit` }}
mkdir -p {{$infrakitHome}}/configs
mkdir -p {{$infrakitHome}}/logs
mkdir -p {{$infrakitHome}}/plugins

# dockerImage  {{ $dockerImage := var "/infrakit/docker/image" }}
# dockerMounts {{ $dockerMounts := `-v /var/run/docker.sock:/var/run/docker.sock -v /infrakit:/infrakit` }}
# dockerEnvs   {{ $dockerEnvs := `-e INFRAKIT_HOME=/infrakit -e INFRAKIT_PLUGINS_DIR=/infrakit/plugins`}}

# echo "Start up Cloudformation integration which reflects on the stack and provides some required info specified in CFN:
# {{ $stackName := var `/cluster/name` }}
# {{ $metadataExportUrl := var `/infrakit/metadata/configURL` }}
# {{ $metadataImage := `infrakit/aws:latest` }}
# {{ $metadataCmd := (cat `metadata --name var --template-url` $metadataExportUrl `--stack` $stackName) }}
# docker run -d --restart always --name cfn-reflect \
#        {{$dockerMounts}} {{$dockerEnvs}} {{$metadataImage}} {{$metadataCmd}}

echo "Cluster {{ var `/cluster/name` }} size is {{ var `/cluster/swarm/size` }}"
echo "alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'" >> /root/.bashrc

alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'

{{ $groupsURL := cat (var `/infrakit/config/root`) `/groups.json` | nospace }}


echo "Starting up infrakit  ######################"
docker run -d --restart always --name infrakit -p 24864:24864 {{ $dockerMounts }} {{ $dockerEnvs }} \
       -e INFRAKIT_AWS_STACKNAME={{ var `/cluster/name` }} \
       -e INFRAKIT_AWS_METADATA_TEMPLATE_URL={{ var `/infrakit/metadata/configURL` }} \
       -e INFRAKIT_MANAGER_BACKEND=swarm \
       -e INFRAKIT_AWS_NAMESPACE_TAGS=infrakit.scope={{ var `/cluster/name` }} \
       -e INFRAKIT_TAILER_PATH=/infrakit/logs/infrakit.log \
       {{$dockerImage}} \
       infrakit plugin start manager group aws swarm ingress time --log 5

# Need a bit of time for the leader to discover itself
sleep 10

# Try to commit - this is idempotent but don't error out and stop the cloud init script!
#echo "Commiting to infrakit $(infrakit manager commit {{$groupsURL}})"
echo "Commiting to infrakit $(docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit manager commit {{$groupsURL}})"
