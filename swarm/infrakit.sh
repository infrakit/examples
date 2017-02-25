{{ source "common.ikt" }}

# Set up infrakit.  This assumes Docker has been installed

{{ $infrakitHome := ref "/infrakit/home" }}
mkdir -p {{$infrakitHome}}/configs
mkdir -p {{$infrakitHome}}/logs
mkdir -p {{$infrakitHome}}/plugins

{{ $dockerMounts := ref "/infrakit/docker/options/mount" }}
{{ $dockerEnvs := ref "/infrakit/docker/options/env" }}

{{ $stackName := ref "/cluster/name" }}
{{ $metadataExportUrl := ref "/cluster/metadata/configURL" }}
{{ $metadataImage := ref "/infrakit/metadata/docker/image" }}
{{ $metadataCmd := (cat "infrakit-metadata-aws --name var --template-url" $metadataExportUrl "--stack" $stackName) }}

{{ if not ref "/cluster/metadata/running" }}
echo "Starting up metadata plugin"
docker run -d --restart always --name metadata \
       {{$dockerMounts}} {{$dockerEnvs}} {{$metadataImage}} {{$metadataCmd}}
sleep 5
{{ end }}

{{/* integration with the metadata plugin here -- note the values here are from the cloudformation metadata */}}
{{ metadata "var/export/cfn/stack" | global "/cluster/name" }}
{{ metadata "var/export/cfn/config/Parameters/ClusterSize/ParameterValue" | global "/cluster/swarm/size" }}
{{ metadata "var/export/cfn/config/Parameters/BootScriptURL/ParameterValue" | global "/cluster/config/bootURL" }}
{{ metadata "var/export/cfn/config/Parameters/InfrakitCore/ParameterValue" | global "/infrakit/docker/image" }}
{{ metadata "var/export/cfn/config/Parameters/InfrakitInstancePlugin/ParameterValue" | global "/infrakit/instance/docker/image" }}
{{ metadata "var/export/cfn/config/Parameters/InfrakitMetadataPlugin/ParameterValue" | global "/infrakit/metadata/docker/image" }}
{{ metadata "var/export/cfn/config/Parameters/MetadataExportTemplate/ParameterValue" | global "/cluster/metadata/configURL" }}

{{ $dockerImage := ref "/infrakit/docker/image" }}

echo "alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'" >> /root/.bashrc

alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'

{{ $pluginsURL := cat (ref "/cluster/config/urlRoot") "/plugins.json" | nospace }}
{{ $groupsURL := cat (ref "/cluster/config/urlRoot") "/groups.json" | nospace }}

{{ $instanceImage := ref "/infrakit/instance/docker/image" }}
{{ $instanceCmd := (cat "infrakit-instance-aws --log 5 --namespace-tags" (cat "infrakit.scope=" $stackName | nospace)) }}


echo "Starting up infrakit"
docker run -d --restart always --name manager \
       {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit-manager --name group  --proxy-for-group group-stateless swarm

docker run -d --restart always --name group-stateless \
       {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit-group-default --poll-interval 5s --name group-stateless

docker run -d --restart always --name flavor-swarm \
       {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit-flavor-swarm --log 5

echo "Starting up instance-aws plugin"
docker run -d --restart always --name instance-plugin \
       {{$dockerMounts}} {{$dockerEnvs}} {{$instanceImage}} {{$instanceCmd}}

# Need a bit of time for the leader to discover itself
sleep 10

# Try to commit - this is idempotent but don't error out and stop the cloud init script!
echo "Commiting to infrakit $(docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit manager commit {{$groupsURL}})"
