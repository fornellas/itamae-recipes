# Requisite:
# - Redirect ports 22/TCP, 80/TCP, 443/TCP and 443/UDP
# - Ensure static DHCP address

hostname = "odroid.sigstop.co.uk"

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

remote_file "/etc/rc.local" do
  mode "755"
  owner "root"
  group "root"
end

file "/etc/cron.d/kernel_reboot" do
  mode "644"
  owner "root"
  group "root"
  content "30 7 * * * root if [ \"$(/bin/ls -1tr /boot/initrd.img-* | /usr/bin/tail -n 1 | /usr/bin/cut -d- -f2-)\" != \"$(uname -r)\" ] ; then /sbin/reboot ; fi
\n"
end

include_recipe "../../cookbooks/base_system"
include_recipe "../../cookbooks/base_server"
include_recipe "../../cookbooks/no_auth_from_securetty"
include_recipe "../../cookbooks/cherrymusic"
include_recipe "../../cookbooks/nextcloud"
include_recipe "../../cookbooks/octoprint"
include_recipe "../../cookbooks/openvpn"
include_recipe "../../cookbooks/tt-rss"
include_recipe "../../cookbooks/prometheus"
include_recipe "../../cookbooks/node_exporter"
include_recipe "../../cookbooks/blackbox_exporter"
include_recipe "../../cookbooks/alertmanager"
include_recipe "../../cookbooks/alertmanager-discord"
include_recipe "../../cookbooks/grafana"
