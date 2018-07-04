include_recipe "../group_add"

##
## Configuration
##

home_path = '/var/lib/octoprint'
port = 5000
octoprint_version = "1.3.8"
domain = 'octoprint.sigstop.co.uk'
email = 'fabio.ornellas@gmail.com'
webcam_server = '192.168.0.150'

##
## SetUp
##

basedir_path = "#{home_path}/.octoprint"
configfile_path = "#{basedir_path}/config.yaml"
virtualenv_path = "#{home_path}/virtualenv"

##
## Packages
##

package 'python-pip'
package 'python-dev'
package 'python-setuptools'
package 'python-virtualenv'
package 'git'
package 'libyaml-dev'
package 'build-essential'

##
## User/Group
##

group 'octoprint'

user 'octoprint' do
	gid 'octoprint'
	home home_path
	system_user true
	shell '/usr/sbin/nologin'
	create_home true
end

group_add 'octoprint' do
	groups ['tty', 'dialout']
end

##
## Octoprint
##

# Virtualenv

execute "virtualenv --python=/usr/bin/python2 #{virtualenv_path}" do
	user 'octoprint'
	not_if "test -d #{virtualenv_path}"
end

# install

pip = "#{virtualenv_path}/bin/pip"

# Fix for https://github.com/foosel/OctoPrint/issues/2687
# Not needed for Octoprint 1.3.9
execute "#{pip} install sarge==0.1.4" do
	user 'octoprint'
	not_if "#{pip} list | grep -E '^sarge +0.1.4'"
end

execute "#{pip} install https://github.com/foosel/OctoPrint/archive/#{octoprint_version}.zip" do
	user 'octoprint'
	not_if "#{pip} list | grep -E '^OctoPrint +'"
end

# sudo

restart_service_cmd = "/usr/bin/sudo /bin/systemctl restart octoprint.service"

file "/etc/sudoers.d/octoprint" do
	mode '644'
	owner 'root'
	group 'root'
	content "octoprint ALL=(ALL:ALL) NOPASSWD:#{restart_service_cmd}\n"
end

# Default Config

execute "mkdir #{basedir_path}" do
	user 'octoprint'
	not_if "test -d #{basedir_path}"
end

template configfile_path do
	mode '644'
	owner 'octoprint'
	group 'octoprint'
	not_if "test -e #{configfile_path}"
	variables(
		serverRestartCommand: restart_service_cmd
	)
end

##
## Service
##

template "/etc/default/octoprint" do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		octoprint_user: 'octoprint',
		basedir: basedir_path,
		configfile: configfile_path,
		port: port,
		daemon: "#{virtualenv_path}/bin/octoprint",
	)
	notifies :restart, 'service[octoprint]', :immediately
end

remote_file '/etc/init.d/octoprint' do
	mode '755'
	owner 'root'
	group 'root'
end

service "octoprint" do
	action :enable
end

##
## Let's encrypt
##

include_recipe "../letsencrypt"

letsencrypt domain

##
## Nginx
##

include_recipe "../nginx"

package "libnginx-mod-http-auth-pam"

remote_file "/etc/pam.d/octoprint" do
	mode '644'
	owner 'root'
	group 'root'
end

template '/etc/nginx/sites-enabled/octoprint' do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		domain: domain,
		port: port,
		webcam_server: webcam_server,
	)
	notifies :restart, 'service[nginx]', :immediately
end