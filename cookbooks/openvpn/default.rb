domain = "vpn.sigstop.co.uk"
port = "443"

letsencrypt_ca = run_command("cat /etc/ssl/certs/DST_Root_CA_X3.pem").stdout.chomp
default_gateway_dev = run_command(
	"/sbin/ip route | /usr/bin/gawk '/^default via/{print $5}'",
).stdout.chomp

default_gateway_dev_addr = run_command(
	"/sbin/ip route list table 0 | gawk '/^local /{if($4==\"#{default_gateway_dev}\"){print $2;exit}}'",
).stdout.chomp

##
## Certificate
##

include_recipe "../letsencrypt"

letsencrypt domain

##
## sysctl
##

file "/etc/sysctl.d/ipv4_forwarding.conf" do
	mode '644'
	owner 'root'
	group 'root'
	content "net.ipv4.conf.all.forwarding=1"
	notifies :restart, 'service[procps]'
end

service 'procps'

##
## PAM
##

package 'libpam-google-authenticator'

remote_file "/etc/pam.d/openvpn" do
	mode '644'
	owner 'root'
	group 'root'
end

##
## Bind
##

include_recipe "../bind"

##
## iptables
##

table = "nat"
rule_specification = "POSTROUTING -o #{default_gateway_dev} ! -s #{default_gateway_dev_addr} -j MASQUERADE"

execute "/sbin/iptables -t #{table} -A #{rule_specification}" do
	user 'root'
	not_if "/sbin/iptables -t #{table} -C #{rule_specification}"
	notifies :run, 'execute[iptables-save]', :immediately
end

execute "iptables-save" do
	action :nothing
	user 'root'
	command = '/sbin/iptables-save > /etc/iptables/rules.v4'
end

##
## Nginx
##

include_recipe "../nginx"

directory "/etc/openvpn/#{domain}/" do
	mode '755'
	owner 'root'
	group 'root'
end

template "/etc/openvpn/#{domain}/#{domain}-udp.ovpn" do
	source "templates/etc/openvpn/domain/domain-udp.ovpn"
	mode '755'
	owner 'root'
	group 'root'
	variables(
		domain: domain,
		port: port,
		letsencrypt_ca: letsencrypt_ca
	)
end

template '/etc/nginx/sites-enabled/openvpn' do
	mode '644'
	owner 'root'
	group 'root'
	variables(domain: domain)
	notifies :restart, 'service[nginx]', :immediately
end

##
## OpenVPN
##

package 'openvpn'

directory "/etc/systemd/system/openvpn@#{domain}.service.d" do
	mode '755'
	owner 'root'
	group 'root'
end

file "/etc/systemd/system/openvpn@#{domain}.service.d/override.conf" do
	mode '644'
	owner 'root'
	group 'root'
	content <<~EOF
		[Service]
		# Required by pam_google_authenticator.so
		ProtectHome=false
		# Required by pam_unix.so
		ProtectSystem=false
	EOF
	notifies :run, 'execute[systemctl daemon-reload]'
end

execute "systemctl daemon-reload" do
	action :nothing
	user 'root'
	notifies :restart, 'service[openvpn]'
end

template "/etc/openvpn/#{domain}.conf" do
	source "templates/etc/openvpn/domain.conf"
	mode '644'
	owner 'root'
	group 'root'
	notifies :restart, 'service[openvpn]'
	variables(domain: domain, port: port)
end

remote_file "/etc/default/openvpn" do
	mode '644'
	owner 'root'
	group 'root'
	notifies :restart, 'service[openvpn]'
end

service 'openvpn'