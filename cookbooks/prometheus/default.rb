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