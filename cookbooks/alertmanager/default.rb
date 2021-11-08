home_path = "/var/lib/alertmanager"
domain = "alertmanager.sigstop.co.uk"
web_listen_port = "9093"
cluster_listen_port = "9094"
nginx_port = "443"
version = "0.23.0"
arch = "armv7"
tar_gz_url = "https://github.com/prometheus/alertmanager/releases/download/v#{version}/alertmanager-#{version}.linux-#{arch}.tar.gz"

include_recipe "../backblaze"
include_recipe "../iptables"

##
## alertmanager
##

# User / Group

group "alertmanager"

user "alertmanager" do
  gid "alertmanager"
  home home_path
  system_user true
  shell "/usr/sbin/nologin"
  create_home true
end

# Install

execute "wget -O alertmanager.tar.gz #{tar_gz_url} && tar zxf alertmanager.tar.gz && chown root.root -R alertmanager-#{version}.linux-#{arch} && rm -rf /opt/alertmanager && mv alertmanager-#{version}.linux-#{arch} /opt/alertmanager && touch /opt/alertmanager/.#{version}.ok" do
  user "root"
  cwd "/tmp"
  not_if "test -f /opt/alertmanager/.#{version}.ok"
end

# Configuration

directory "/etc/alertmanager" do
  owner "root"
  group "root"
  mode "755"
end

remote_file "/etc/alertmanager/alertmanager.yml" do
  mode "644"
  owner "root"
  group "root"
  notifies :restart, "service[alertmanager]"
end

# Backup

backblaze "#{node["fqdn"].tr(".", "-")}-alertmanager" do
  backup_paths [home_path]
  cron_hour 6
  cron_minute 15
  user "alertmanager"
  bin_path home_path
end

# iptables

iptables_rule_drop_not_user "Drop not www-data|prometheus user to alertmanager" do
  users ["www-data", "prometheus"]
  port web_listen_port
end

iptables_rule_drop_not_user "Drop not prometheus user to alertmanager" do
  users ["prometheus"]
  port cluster_listen_port
end

# Service

template "/etc/systemd/system/alertmanager.service" do
  mode "644"
  owner "root"
  group "root"
  variables(
    install_path: "/opt/alertmanager",
    config_file: "/etc/alertmanager/alertmanager.yml",
    storage_path: home_path,
    web_listen_address: "127.0.0.1:#{web_listen_port}",
    cluster_listen_address: "127.0.0.1:#{cluster_listen_port}",
  )
  notifies :run, "execute[systemctl daemon-reload]"
end

execute "systemctl daemon-reload" do
  action :nothing
  user "root"
  notifies :restart, "service[alertmanager]"
end

service "alertmanager" do
  action :enable
end

##
## Let's Encrypt
##

include_recipe "../letsencrypt"

letsencrypt domain

##
## Nginx
##

include_recipe "../nginx"

package "libnginx-mod-http-auth-pam"

remote_file "/etc/pam.d/alertmanager" do
  mode "644"
  owner "root"
  group "root"
end

template "/etc/nginx/sites-enabled/alertmanager" do
  mode "644"
  owner "root"
  group "root"
  variables(
    domain: domain,
    port: nginx_port,
    alertmanager_port: web_listen_port,
  )
  notifies :restart, "service[nginx]", :immediately
end
