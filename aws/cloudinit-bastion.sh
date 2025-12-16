#!/bin/bash
#cloud-config
set -euo pipefail

apt-get update -y
# Install Ansible if not present
if ! command -v ansible >/dev/null; then
    echo "Installing Ansible and Git..."
    apt-get install -y ansible git
fi

echo "Enabling IP forwarding..."
cat <<EOF >/etc/sysctl.d/99-forwarding.conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl --system

# Clone the bastion Ansible project
echo "Cloning bastion Ansible project..."
git clone https://github.com/Laniakea-elixir-it/ansible-role-vpn-bastion.git /root/ansible-bastion

export ANSIBLEPATH=/root/ansible-bastion
export ROLESPATH=$ANSIBLEPATH/roles
mkdir -p "$ROLESPATH"

echo "Installing Ansible roles dependencies (if requirements.yml exists)..."
if [ -f "$ANSIBLEPATH/requirements.yml" ]; then
    ansible-galaxy role install -p "$ROLESPATH" -r "$ANSIBLEPATH/requirements.yml"
else
    echo "No requirements.yml found. Skipping role dependencies installation."
fi

# Execute the main Ansible playbook
echo "Executing the main bastion playbook (site.yml)..."
ansible-playbook "$ANSIBLEPATH/site.yml" -i "$ANSIBLEPATH/inventory_sample"
