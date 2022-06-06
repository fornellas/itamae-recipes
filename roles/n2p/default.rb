hostname = "n2p.sigstop.co.uk"

update_hostname_command = "/bin/hostname #{hostname} && /usr/bin/touch /var/run/reboot-required"

file "/etc/hostname" do
  mode "644"
  owner "root"
  group "root"
  content "#{hostname}"
  notifies :run, "execute[#{update_hostname_command}]", :immediately
end

execute update_hostname_command do
  user "root"
  action :nothing
end

include_recipe "../../cookbooks/base_system"
include_recipe "../../cookbooks/fornellas"
include_recipe "../../cookbooks/base_server"
include_recipe "../../cookbooks/no_auth_from_securetty"
include_recipe "../../cookbooks/monitoring"
include_recipe "home"
include_recipe "../../cookbooks/node_exporter"
include_recipe "../../cookbooks/iptables_exporter"
include_recipe "../../cookbooks/cherrymusic"
include_recipe "../../cookbooks/octoprint"
include_recipe "../../cookbooks/openvpn"
include_recipe "../../cookbooks/nextcloud"
include_recipe "../../cookbooks/ttrss"
