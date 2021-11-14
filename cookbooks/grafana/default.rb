version = "8.2.3"
arch = "armhf"
domain = "grafana.sigstop.co.uk"
nginx_port = "443"
grafana_port = "3000"

include_recipe "../iptables"

##
## Grafana
##

# Install

execute "Install Grafana" do
  command "wget -O /tmp/grafana.deb https://dl.grafana.com/oss/release/grafana_#{version}_#{arch}.deb && dpkg -i /tmp/grafana.deb ; rm -f /tmp/grafana.deb"
  not_if "/usr/bin/test \"$(dpkg -s grafana | gawk '/^Version: /{print $2}')\" = \"#{version}\""
end

# Configuration

remote_file "/etc/grafana/grafana.ini" do
  mode "640"
  owner "root"
  group "grafana"
  notifies :restart, "service[grafana-server]"
end

# iptables

iptables_rule_drop_not_user "Drop not www-data user to Grafana" do
  users ["www-data"]
  port grafana_port
end

# Service

service "grafana-server" do
  action :enable
end

##
## Backup
##

include_recipe "../backblaze"

package "sqlite3"

backblaze "#{node["fqdn"].tr(".", "-")}-grafana" do
  backup_paths ["/var/lib/grafana/"]
  backup_exclude ["grafana.db"]
  backup_cmd_stdout "sqlite3 /var/lib/grafana/grafana.db .dump"
  backup_cmd_stdout_filename "grafana.db"
  cron_hour 5
  cron_minute 30
  user "grafana"
  group "grafana"
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

remote_file "/etc/pam.d/grafana" do
  mode "644"
  owner "root"
  group "root"
end

template "/etc/nginx/sites-enabled/grafana" do
  mode "644"
  owner "root"
  group "root"
  variables(
    domain: domain,
    port: nginx_port,
    grafana_port: grafana_port,
  )
  notifies :restart, "service[nginx]", :immediately
end
