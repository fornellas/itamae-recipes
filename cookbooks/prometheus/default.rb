domain = "prometheus.sigstop.co.uk"
prometheus_port = "9090"
nginx_port = "443"

##
## Prometheus
##

# Install

package 'prometheus'

# Configuration

remote_file "/etc/prometheus/prometheus.yml" do
	mode '644'
	owner 'root'
	group 'root'
 	notifies :restart, 'service[prometheus]'
end

remote_file "/etc/default/prometheus" do
	mode '644'
	owner 'root'
	group 'root'
 	notifies :restart, 'service[prometheus]'
end

# Service

service "prometheus" do
	action :enable
end

##
## Backup
##

include_recipe "../backblaze"

backblaze "#{node['fqdn'].tr('.', '-')}-prometheus" do
	command_before "/usr/bin/curl -s -XPOST http://localhost:#{prometheus_port}/api/v1/admin/tsdb/snapshot > /dev/null"
	backup_paths ["/var/lib/prometheus/metrics2/snapshots"]
	command_after "/bin/rm -rf /var/lib/prometheus/metrics2/snapshots/*"
  cron_minute 0
  cron_hour 33
	user 'prometheus'
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