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

runcmd:
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

  - ['/usr/bin/po_notify.sh', 'Tailscale installed', 'Installed Tailscale on server ${name}']

  # K3S setup
  # =========
  #
  - ['sh', '-c', 'curl -sfL https://get.k3s.io | sh -']

  - ['/usr/bin/po_notify.sh', 'K3S installed', 'Installed K3S on server ${name}']

  # Install ArgoCD
  # ==============
  #
  - ['kubectl', 'create', 'namespace', 'argocd']
  - ['kubectl', 'apply', '-n', 'argocd', '-f', '${argocd_source}']

  - ['/usr/bin/po_notify.sh', 'ArgoCD installed', 'Installed ArgoCD on server ${name}']
