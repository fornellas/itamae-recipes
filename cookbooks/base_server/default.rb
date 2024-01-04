node.validate! do
  {
    network: {
      local: string,
    },
  }
end

# Base Server

package "ifupdown"
package "systemd-timesyncd"
package "plymouth" do
  action :remove
end

include_recipe "../../cookbooks/postfix"

trusted_network_addresses = [
  "127.0.0.0/8",
  "::1/128",
  node[:network][:local],
]

##
## root
##

execute "Lock root account" do
  user "root"
  command "passwd -l root"
  not_if "getent shadow root | cut -d: -f2 | cut -c 1 | grep -E '^\!$'"
end

##
## OpenSSH Server
##

package "libpam-google-authenticator"

template "/etc/security/access-no-google-authenticator.conf" do
  owner "root"
  group "root"
  mode "644"
  variables(no_google_authenticator_networks: trusted_network_addresses)
end

remote_file "/etc/pam.d/common-auth-google-authenticator" do
  owner "root"
  group "root"
  mode "644"
end

package "openssh-server"

file "/etc/pam.d/sshd" do
  action :edit
  block do |content|
    after = "\n@include common-auth\n"
    add = <<~EOF
      # Google Authenticator
      @include common-auth-google-authenticator
    EOF
    unless content.include?(add)
      s = content.split(after)
      raise "'#{after}' not found exactly one time!" unless s.length == 2
      content.replace("#{s.first}#{after}\n#{add}#{s.last}")
    end
  end
end

template "/etc/ssh/sshd_config" do
  owner "root"
  group "root"
  mode "644"
  variables(trusted_network_addresses: trusted_network_addresses)
  notifies :restart, "service[ssh]", :immediately
end

service "ssh" do
  action [:enable, :start]
end

##
## Unattended Upgrades
##

package "apt-listchanges"
package "unattended-upgrades"

remote_file "/etc/apt/apt.conf.d/50unattended-upgrades" do
  owner "root"
  group "root"
  mode "644"
  notifies :restart, "service[unattended-upgrades]", :immediately
end

service "unattended-upgrades" do
  action [:enable, :start]
end