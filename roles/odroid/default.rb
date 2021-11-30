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
include_recipe "../../cookbooks/prometheus"

prometheus_file_sd "brown_windows_exporter" do
  targets [
    { hosts: ["192.168.0.221:9182"] },
    labels: { instance: "brown.local:9182" },
  ]
end

prometheus_file_sd "brown_node_exporter" do
  targets [
    { hosts: ["192.168.0.221:9100"] },
    labels: { instance: "brown.local:9100" },
  ]
end

prometheus_file_sd "odroid_node_exporter" do
  targets [
    { hosts: ["127.0.0.1:9100"] },
    labels: { instance: "odroid.local:9100" },
  ]
end

prometheus_file_sd "odroid_node_exporter" do
  targets [
    { hosts: ["127.0.0.1:9100"] },
    labels: { instance: "odroid.local:9100" },
  ]
end

prometheus_file_sd "office_sensors" do
  targets [
    { hosts: ["192.168.0.138:9090"] },
    labels: { instance: "office_sensors.local:9090" },
  ]
end

prometheus_file_sd "living_room_sensors" do
  targets [
    { hosts: ["192.168.0.124:9090"] },
    labels: { instance: "living_room_sensors:9090" },
  ]
end

include_recipe "../../cookbooks/node_exporter"
include_recipe "../../cookbooks/blackbox_exporter"
include_recipe "../../cookbooks/iptables_exporter"
include_recipe "../../cookbooks/alertmanager"
include_recipe "../../cookbooks/grafana"
include_recipe "../../cookbooks/no_auth_from_securetty"
include_recipe "../../cookbooks/cherrymusic"
include_recipe "../../cookbooks/nextcloud"
include_recipe "../../cookbooks/octoprint"
include_recipe "../../cookbooks/openvpn"
include_recipe "../../cookbooks/tt-rss"
