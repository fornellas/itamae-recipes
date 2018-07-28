domain = "nextcloud.sigstop.co.uk"
port = "443"
nextcloud_version = "13.0.4"
php_major_version = "7"
php_minor_version = "2"
php_version = "#{php_major_version}.#{php_minor_version}"
socket_path = "/run/php/php#{php_version}-fpm-nextcloud.sock"
home_path = '/var/lib/nextcloud'
install_path = "#{home_path}/NextCloud"

##
## Deps
##

include_recipe "../mysql"
include_recipe "../php-fpm"

package "php#{php_version}-common"
package "php#{php_version}-xml"
package "php#{php_version}-gd"
package "php#{php_version}-json"
package "libxml2"
package "php#{php_version}-mbstring"
package "php#{php_version}-zip"
package "php#{php_version}-mysql"
package "php#{php_version}-curl"
package "php#{php_version}-bz2"
package "php#{php_version}-intl"
package "php#{php_version}-gmp"
package "php-imagick"
package "ffmpeg"
package "libreoffice"

##
## User / Group
##

group 'nextcloud'

user 'nextcloud' do
	gid 'nextcloud'
	home home_path
	system_user true
	shell '/usr/sbin/nologin'
	create_home true
end

##
## NextCloud
##

# NextCloud

git install_path do
	user 'nextcloud'
	revision "v#{nextcloud_version}"
	repository "https://github.com/nextcloud/server.git"
end

# 3rdparty

execute "git submodule update --init" do
	user 'nextcloud'
	cwd install_path
	only_if "git submodule status | grep -E '^-'"
end

# FPM

template "/etc/php/#{php_version}/fpm/pool.d/nextcloud.conf" do
	source "templates/etc/php/fpm/pool.d/nextcloud.conf"
	mode '644'
	owner 'root'
	group 'root'
	variables(
		prefix: install_path,
		socket_path: socket_path,
	)
	notifies :restart, "service[php#{php_version}-fpm]"
end

# Cron

file "/etc/cron.d/nextcloud" do
	mode '644'
	owner 'root'
	group 'root'
	content <<~EOF
		*/15  *  *  *  * nextcloud /usr/bin/php#{php_version} -f #{install_path}/cron.php
	EOF
end

##
## Nginx
##

# Let's Encrypt

include_recipe "../letsencrypt"
letsencrypt domain

# Nginx

include_recipe "../nginx"

package "libnginx-mod-http-auth-pam"

template '/etc/nginx/sites-enabled/nextcloud' do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		domain: domain,
		port: port,
		fpm_pool_prefix: install_path,
		socket_path: socket_path,
	)
	notifies :restart, 'service[nginx]', :immediately
end

##
## Backup
##

# https://docs.nextcloud.com/server/12/admin_manual/maintenance/backup.html

backblaze "#{node['fqdn'].tr('.', '-')}-nextcloud" do
	command_before "sudo -u nextcloud /usr/bin/php#{php_version} #{install_path}/occ maintenance:mode --on > /dev/null"
	backup_paths [
		"#{install_path}/config/",
		"#{install_path}/data/",
		"#{install_path}/themes/",
	]
	backup_cmd_stdout '/usr/bin/mysqldump nextcloud'
	backup_cmd_stdout_filename "nextcloud.sql"
	command_after "sudo -u nextcloud /usr/bin/php#{php_version} #{install_path}/occ maintenance:mode --off > /dev/null"
	user 'nextcloud'
	cron_minute 55
end