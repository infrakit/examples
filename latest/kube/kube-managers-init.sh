#!/bin/sh
set -o errexit
set -o nounset
set -o xtrace

{{/* Install Kubeadm */}}
{{ include "install-kubeadm.sh" }}

{{ if BOOTSTRAP }}
# Bootstrap node
kubeadm init --skip-preflight-checks --token {{ KUBEADM_JOIN_TOKEN }}
export KUBECONFIG=/etc/kubernetes/admin.conf
{{ if ADDON "network" }}
    kubectl apply -f {{ ADDON "network" }}
{{ end }}
{{ if ADDON "visualise" }}
    kubectl apply -f {{ ADDON "visualise" }}
{{ end }}
{{ end }}{{/* bootstrap */}}

{{ if WORKER }}
# Worker mode -- if a node with a logical ID isn't part of the control plane.
kubeadm join --skip-preflight-checks --token {{ KUBEADM_JOIN_TOKEN }} {{ KUBE_JOIN_IP }}:{{ BIND_PORT }}
{{ end }}
