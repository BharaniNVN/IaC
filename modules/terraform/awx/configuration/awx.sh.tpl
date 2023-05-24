#!/usr/bin/env bash

# Logs can be found at the following locations:
# - /var/log/custom_script.log
# - /var/lib/waagent/custom-script/download/0/
# - /var/log/waagent.log

# Stop on error
set -e

# Add repositories
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo -y &>> /var/log/custom_script.log

# Install Ansible
dnf install python3-pip-9.0.3-16.el8 -y &>> /var/log/custom_script.log
pip3 install ansible==2.9.10 &>> /var/log/custom_script.log
  
# Add Ansible to PATH
/usr/local/bin/ansible -m=lineinfile -a='path=/etc/profile line="PATH=$PATH:/usr/local/bin"' localhost
source /etc/profile

# Configure firewall
ansible -m=firewalld -a='zone=public masquerade=yes permanent=yes state=enabled' localhost
ansible -m=firewalld -a='zone=public interface=docker0 permanent=yes state=enabled' localhost
ansible -m=firewalld -a='zone=public port=80/tcp permanent=yes state=enabled' localhost

# Install Docker prerequisites
ansible -m=dnf -a='name=git,gcc,gcc-c++,nodejs,gettext,device-mapper-persistent-data,lvm2,bzip2,wget,unzip' localhost
 
# Set Python3 as a default Python version
ansible -m=alternatives -a='name=python path=/usr/bin/python3' localhost
 
# Install and start Docker
ansible -m=dnf -a='name=docker-ce-3:18.09.1-3.el7' localhost 
ansible -m=service -a='name=docker enabled=yes state=started' localhost

# Install Docker Compose
ansible -m=pip -a='name=docker-compose' localhost

# Get AWX
ansible -m=get_url -a='url=https://github.com/ansible/awx/archive/${awx_version}.zip dest=/root/awx.zip' localhost
ansible -m=unarchive -a='src=/root/awx.zip dest=/root' localhost

# Configure AWX
ansible -m=lineinfile -a='path=/root/awx-${awx_version}/installer/inventory regexp="^admin_user.*" line="admin_user=${awx_admin_username}"' localhost
ansible -m=lineinfile -a='path=/root/awx-${awx_version}/installer/inventory regexp="^admin_password.*" line="admin_password=${awx_admin_password}"' localhost
ansible -m=lineinfile -a='path=/root/awx-${awx_version}/installer/inventory regexp="^secret_key.*" line="secret_key=${awx_secret_key}"' localhost
  
ansible -m=lineinfile -a='path=/root/awx-${awx_version}/installer/inventory regexp="^pg_username.*" line="pg_username=${awx_database_server_username}"' localhost
ansible -m=lineinfile -a='path=/root/awx-${awx_version}/installer/inventory regexp="^pg_password.*" line="pg_password=${awx_database_server_password}"' localhost
ansible -m=lineinfile -a='path=/root/awx-${awx_version}/installer/inventory regexp="^pg_database.*" line="pg_database=${awx_database_name}"' localhost
ansible -m=lineinfile -a='path=/root/awx-${awx_version}/installer/inventory regexp="^pg_port.*" line="pg_port=${awx_database_server_port}"' localhost
%{ if awx_database_server_type != "Local" }
ansible -m=lineinfile -a='path=/root/awx-${awx_version}/installer/inventory regexp="^# pg_hostname.*" line="pg_hostname=${awx_database_server_fqdn}"' localhost
%{ endif }
 
# Install AWX
ansible-playbook -i /root/awx-${awx_version}/installer/inventory /root/awx-${awx_version}/installer/install.yml

# Reload firewall configuration
ansible -m=systemd -a='name=firewalld state=reloaded' localhost