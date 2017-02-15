#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

{{/* Before we call the common boot sequence, set a few variables */}}

{{ global "/cluster/swarm/initialized" SWARM_INITIALIZED }}
{{ global "/cluster/swarm/join/ip" INSTANCE_LOGICAL_ID }}

{{ global "/local/docker/engine/labels" INFRAKIT_LABELS }}
{{ global "/local/docker/swarm/join/addr" SWARM_MANAGER_ADDR }}
{{ global "/local/docker/swarm/join/token" SWARM_JOIN_TOKENS.Manager }}

{{ global "/local/infrakit/role/manager" true }}

{{ include "boot.sh" }}

# Append commands here to run other things that makes sense for managers
