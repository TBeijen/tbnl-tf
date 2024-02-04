#cloud-config
# The above header must generally appear on the first line of a cloud config
# file, but all other lines that begin with a # are optional comments.

write_files:
- path: /usr/bin/po_notify.sh
  owner: root:root
  permissions: '0777'
  content: |
    #!/bin/bash
    curl -s -F "token=${pushover_api_token}" \
    -F "user=${pushover_user_key}" \
    -F "title=$1" \
    -F "message=$2" https://api.pushover.net/1/messages.json
- path: /etc/systemd/system/notifyReboot.service
  owner: root:root
  permissions: '0644'
  content: |
    [Unit]
    Description=Send PushOver notification on reboot
    Requires=network-online.target
    After=network-online.target

    [Service]
    ExecStart=/usr/bin/po_notify.sh "Server rebooted" "The server %H has rebooted"

    [Install]
    WantedBy=multi-user.target
- path: /root/.aws/config
  owner: root:root
  permissions: '0644'
  content: |
    [default]
    output = json
    region = eu-west-1
- path: /root/.aws/credentials
  owner: root:root
  permissions: '0600'
  content: |
    [default]
    aws_access_key_id = ${aws_access_key_id}
    aws_secret_access_key = ${aws_secret_access_key}

runcmd:
  # Systemd setup
  #
  # Activate notify on boot service
  - ['systemctl', 'daemon-reload']
  - ['systemctl', 'enable', 'notifyReboot.service']

  # Tailscale setup
  # ===============
  # 
  # One-command install, from https://tailscale.com/download/
  - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
  # Set sysctl settings for IP forwarding (useful when configuring an exit node)
  # - ['sh', '-c', "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf" ]
  # Generate an auth key from your Admin console
  # https://login.tailscale.com/admin/settings/keys
  # and replace the placeholder below
  - ['tailscale', 'up', '--authkey=${tailscale_auth_key}']
  # Optional: Include this line to make this node available over Tailscale SSH
  - ['tailscale', 'set', '--ssh']
  # Optional: Include this line to configure this machine as an exit node
  # - ['tailscale', 'set', '--advertise-exit-node']

  - ['/usr/bin/po_notify.sh', 'Tailscale installed', 'Installed Tailscale on server ${instance_name}']

  # K3S setup
  # =========
  #
  - ['sh', '-c', 'curl -sfL https://get.k3s.io | sh -']

  - ['/usr/bin/po_notify.sh', 'K3S installed', 'Installed K3S on server ${instance_name}']

  # AWS CLI & store kubeconfig
  # ==========================
  #
  - |
    export NEEDRESTART_SUSPEND=suspend
    apt install awscli -y
  - |
    cat /etc/rancher/k3s/k3s.yaml | sed -E "s/: default/: ${instance_name}/g" | sed -E "s/127.0.0.1/${instance_name}/g" > /root/${instance_name}
  - |
    aws ssm put-parameter --region eu-west-1 --overwrite --name "${aws_ssm_target_kubeconfig}" --value file:///root/${instance_name} --type SecureString

  # Install ArgoCD
  # ==============
  #
  - ['kubectl', 'create', 'namespace', 'argocd']
  - ['kubectl', 'apply', '-n', 'argocd', '-f', '${argocd_install_source}']

  # bootstrap with app-of-apps, setting the cluster name
  - |
    curl -s "${argocd_app_of_apps_source}" \
        | sed 's/__ENVIRONMENT__/${environment}/g' \
        | sed 's/__CLUSTER_NAME__/${cluster_name}/g' \
        | sed 's/__TARGET_REVISION__/${target_revision}/g' \
        | kubectl apply -n argocd -f -

  - ['/usr/bin/po_notify.sh', 'ArgoCD installed', 'Installed ArgoCD on server ${instance_name}']

  # Provide ESO secret
  # ==================
  - |
    sed '/\[default\]/d; s/ //g' /root/.aws/credentials > /root/.aws/credentials.eso
    kubectl create namespace external-secrets
    kubectl -n external-secrets create secret generic aws-secret --from-env-file=/root/.aws/credentials.eso && /usr/bin/po_notify.sh 'Set up ESO secret' 'Set up ESO secret on server ${instance_name}'

  # Updates & disable auto-update
  # =============================
  #
  - ['systemctl', 'stop', 'unattended-upgrades.service']
  - ['systemctl', 'disable', 'unattended-upgrades.service']
  - |
    export NEEDRESTART_SUSPEND=suspend
    export DEBIAN_FRONTEND=noninteractive
    apt -s dist-upgrade | grep "^Inst" | grep -i securi | awk -F " " {'print $2'} | xargs apt install -y
  
  - ['/usr/bin/po_notify.sh', 'Security updates installed', 'Installed security updates on server ${instance_name}.']

  # (Needrestart seems to always prevent interactive prompt when kernel update requires reboot, so triggering reboot ourselves.)
  - |
    if [ -f /var/run/reboot-required ]; then
      /usr/bin/po_notify.sh "Rebooting" "Rebooting server ${instance_name}"
      reboot now
    else
      /usr/bin/po_notify.sh "Restarting services" "Executing needrestart on server ${instance_name}"
      needrestart -r a
    fi
