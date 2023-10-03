#!/usr/bin/env bash

kube_config_path="${CONFIG_PATH:-$HOME/workspaces/p/tbnl/.kube/}"
kube_ssm_path="${SSM_PATH:-/tbnl-tf/prod/kubeconfig/}"

mkdir -p ${kube_config_path}
aws ssm get-parameters-by-path --path "${kube_ssm_path}" |jq -r .Parameters[].Name | while read CONF; do
    echo $CONF

    echo $(dirname $kube_config_path)
    echo $(basename $CONF)
    aws ssm get-parameter --name ${CONF} --with-decryption --output json \
        | jq -r .Parameter.Value \
        > "${kube_config_path}/$(basename $CONF)" 
done
