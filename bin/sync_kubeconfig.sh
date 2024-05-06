#!/usr/bin/env bash

kube_config_base_dir="${CONFIG_PATH:-$HOME/workspaces/tbnl/}"
kube_ssm_path="${SSM_PATH:-/tbnl-tf/dev/kubeconfig/}"

aws_account=$(aws sts get-caller-identity |jq -r '.Account')
aws_env=""
if [[ $aws_account == "296093601437" ]]; then
  aws_env=dev
fi
if [[ $aws_account == "248624703507" ]]; then
  aws_env=dev
fi
echo "AWS env = ${aws_env}"

kube_config_path="${kube_config_base_dir}.${aws_env}-kube"
mkdir -p ${kube_config_path}
aws ssm get-parameters-by-path --path "${kube_ssm_path}" |jq -r .Parameters[].Name | while read CONF; do
    echo $CONF

    echo $(dirname $kube_config_path)
    echo $(basename $CONF)
    aws ssm get-parameter --name ${CONF} --with-decryption --output json \
        | jq -r .Parameter.Value \
        > "${kube_config_path}/$(basename $CONF)"
    chmod 0600 "${kube_config_path}/$(basename $CONF)"
done
