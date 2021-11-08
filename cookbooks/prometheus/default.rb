home_path = "/var/lib/prometheus"
domain = "prometheus.sigstop.co.uk"
web_listen_port = "9090"
nginx_port = "443"
version = "2.31.0"
arch = "armv7"
tar_gz_url = "https://github.com/prometheus/prometheus/releases/download/v#{version}/prometheus-#{version}.linux-#{arch}.tar.gz"

include_recipe "../backblaze"
include_recipe "../iptables"

##
## Prometheus
##

# User / Group

group "prometheus"

user "prometheus" do
  gid "prometheus"
  home home_path
  system_user true
  shell "/usr/sbin/nologin"
  create_home true
end

# Install

execute "wget -O prometheus.tar.gz #{tar_gz_url} && tar zxf prometheus.tar.gz && chown root.root -R prometheus-#{version}.linux-#{arch} && rm -rf /opt/prometheus && mv prometheus-#{version}.linux-#{arch} /opt/prometheus && touch /opt/prometheus/.#{version}.ok" do
  user "root"
  cwd "/tmp"
  not_if "test -f /opt/prometheus/.#{version}.ok"
end

# Configuration

directory "/etc/prometheus" do
  owner "root"
  group "root"
  mode "755"
end

remote_file "/etc/prometheus/prometheus.yml" do
  mode "644"
  owner "root"
  group "root"
  notifies :restart, "service[prometheus]"
end

# Backup

backblaze "#{node["fqdn"].tr(".", "-")}-prometheus" do
  command_before "/usr/bin/curl -s -XPOST http://localhost:#{web_listen_port}/api/v1/admin/tsdb/snapshot > /dev/null"
  backup_paths ["#{home_path}/tsdb/snapshots"]
  command_after "/bin/rm -rf #{home_path}/tsdb/snapshots/*"
  cron_hour 6
  cron_minute 0
  user "prometheus"
  bin_path home_path
end

# iptables

iptables_rule_drop_not_user "Drop not www-data|grafana user to Prometheus" do
  users ["www-data", "grafana"]
  port web_listen_port
end

# Service

template "/etc/systemd/system/prometheus.service" do
  mode "644"
  owner "root"
  group "root"
  variables(
    install_path: "/opt/prometheus",
    config_file: "/etc/prometheus/prometheus.yml",
    storage_tsdb_path: "#{home_path}/tsdb",
    web_listen_address: "127.0.0.1:#{web_listen_port}",
  )
  notifies :run, "execute[systemctl daemon-reload]"
end

execute "systemctl daemon-reload" do
  action :nothing
  user "root"
  notifies :restart, "service[prometheus]"
end

service "prometheus" do
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

remote_file "/etc/pam.d/prometheus" do
  mode "644"
  owner "root"
  group "root"
end

template "/etc/nginx/sites-enabled/prometheus" do
  mode "644"
  owner "root"
  group "root"
  variables(
    domain: domain,
    port: nginx_port,
    prometheus_port: web_listen_port,
  )
  notifies :restart, "service[nginx]", :immediately
end
