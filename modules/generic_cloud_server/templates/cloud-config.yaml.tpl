#cloud-config
# The above header must generally appear on the first line of a cloud config
# file, but all other lines that begin with a # are optional comments.

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
  - ['tailscale', 'up', '--authkey=${auth_key}']
  # Optional: Include this line to make this node available over Tailscale SSH
  - ['tailscale', 'set', '--ssh']
  # Optional: Include this line to configure this machine as an exit node
  # - ['tailscale', 'set', '--advertise-exit-node']

  # K3S setup
  # =========
  #
  - ['sh', '-c', 'curl -sfL https://get.k3s.io | sh -']
