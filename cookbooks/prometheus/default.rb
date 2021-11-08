home_path = "/var/lib/prometheus"
domain = "prometheus.sigstop.co.uk"
prometheus_port = "9090"
nginx_port = "443"
version = "2.31.0"
arch = "armv7"
tar_gz_url = "https://github.com/prometheus/prometheus/releases/download/v#{version}/prometheus-#{version}.linux-#{arch}.tar.gz"

include_recipe "../../cookbooks/blackbox_exporter"

##
## Prometheus
##

# User / Group

group 'prometheus'

user 'prometheus' do
	gid 'prometheus'
	home home_path
	system_user true
	shell '/usr/sbin/nologin'
	create_home true
end

# Install

execute "wget -O prometheus.tar.gz #{tar_gz_url} && tar zxf prometheus.tar.gz && chown root.root -R prometheus-#{version}.linux-#{arch} && rm -rf /opt/prometheus-tmp && mv prometheus-#{version}.linux-#{arch} /opt/prometheus-tmp && mv /opt/prometheus-tmp /opt/prometheus-#{version}" do
	user 'root'
	cwd "/tmp"
	not_if "test -d /opt/prometheus-#{version}"
end

# Configuration

directory "/etc/prometheus" do
    owner 'root'
    group 'root'
    mode '755'
end

remote_file "/etc/prometheus/prometheus.yml" do
	mode '644'
	owner 'root'
	group 'root'
 	notifies :restart, 'service[prometheus]'
end

# Backup

include_recipe "../backblaze"

backblaze "#{node['fqdn'].tr('.', '-')}-prometheus" do
	command_before "/usr/bin/curl -s -XPOST http://localhost:#{prometheus_port}/api/v1/admin/tsdb/snapshot > /dev/null"
	backup_paths ["#{home_path}/tsdb/snapshots"]
	command_after "/bin/rm -rf #{home_path}/tsdb/snapshots/*"
	cron_hour 6
	cron_minute 0
	user 'prometheus'
	bin_path home_path
end

# Service

template "/etc/systemd/system/prometheus.service" do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		install_path: "/opt/prometheus-#{version}",
		config_file: "/etc/prometheus/prometheus.yml",
		storage_tsdb_path: "#{home_path}/tsdb",
	)
	notifies :run, 'execute[systemctl daemon-reload]'
end

execute "systemctl daemon-reload" do
	action :nothing
	user 'root'
	notifies :restart, 'service[prometheus]'
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
	mode '644'
	owner 'root'
	group 'root'
end

template '/etc/nginx/sites-enabled/prometheus' do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		domain: domain,
		port: nginx_port,
		prometheus_port: prometheus_port,
	)
	notifies :restart, 'service[nginx]', :immediately
end