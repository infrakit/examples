#!/bin/sh
set -o errexit
set -o nounset
set -o xtrace

{{ include "install-kubeadm.sh" }}
kubeadm join --token {{ KUBEADM_JOIN_TOKEN }} {{ KUBE_JOIN_IP }}:{{ BIND_PORT }}
