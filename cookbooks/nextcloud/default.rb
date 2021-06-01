domain = "nextcloud.sigstop.co.uk"
port = "443"
# Must upgrade step by step:
# https://docs.nextcloud.com/server/20/admin_manual/maintenance/upgrade.html#how-to-upgrade
nextcloud_version = "20.0.8"

php_major_version = "7"
php_minor_version = "2"
php_version = "#{php_major_version}.#{php_minor_version}"
socket_path = "/run/php/php#{php_version}-fpm-nextcloud.sock"
home_path = '/var/lib/nextcloud'
install_path = "#{home_path}/NextCloud"
occ = "sudo -u nextcloud /usr/bin/php#{php_version} #{install_path}/occ"

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

# Unpack

unpack_command = <<-EOF
	set -e
	# Download
	cd /tmp
	rm -f nextcloud-#{nextcloud_version}.tar.bz2
	wget https://download.nextcloud.com/server/releases/nextcloud-#{nextcloud_version}.tar.bz2
	# Unpack
	rm -rf #{home_path}/nextcloud
	tar jxf nextcloud-#{nextcloud_version}.tar.bz2 -C #{home_path}
	rm -rf #{install_path}
	mv #{home_path}/nextcloud #{install_path}
	# Clean
	rm -rf #{install_path}/config
	rm -rf #{install_path}/data
	rm -rf #{install_path}/themes
	# Done!
	touch #{install_path}/.ok.#{nextcloud_version}
EOF

execute unpack_command do
	user 'nextcloud'
  not_if "test -e #{install_path}/.ok.#{nextcloud_version}"
end

# Symlinks

directory "#{home_path}/config" do
    owner 'nextcloud'
    group 'nextcloud'
    mode '755'
end

link "#{install_path}/config" do
	user 'nextcloud'
	to "#{home_path}/config"
end

directory "#{home_path}/data" do
    owner 'nextcloud'
    group 'nextcloud'
    mode '770'
end

link "#{install_path}/data" do
	user 'nextcloud'
	to "#{home_path}/data"
end

directory "#{home_path}/themes" do
    owner 'nextcloud'
    group 'nextcloud'
    mode '755'
end

link "#{install_path}/themes" do
	user 'nextcloud'
	to "#{home_path}/themes"
end

# Upgrade

execute "#{occ} maintenance:mode --on && #{occ} upgrade && #{occ} maintenance:mode --off && touch #{install_path}/.ok.#{nextcloud_version}.upgrade" do
  not_if "test -e #{install_path}/.ok.#{nextcloud_version}.upgrade"
end

# https://docs.nextcloud.com/server/20/admin_manual/maintenance/upgrade.html#long-running-migration-steps

execute "#{occ} db:add-missing-indices && touch #{install_path}/.ok.#{nextcloud_version}.db_add-missing-indices" do
  not_if "test -e #{install_path}/.ok.#{nextcloud_version}.db_add-missing-indices"
end

execute "#{occ} db:add-missing-columns && touch #{install_path}/.ok.#{nextcloud_version}.db_add-missing-columns" do
  not_if "test -e #{install_path}/.ok.#{nextcloud_version}.db_add-missing-columns"
end

##
## FPM
##

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
	command_before "#{occ} maintenance:mode --on &> /dev/null"
	backup_paths [
		"#{install_path}/config/",
		"#{install_path}/data/",
		"#{install_path}/themes/",
	]
	backup_cmd_stdout '/usr/bin/mysqldump nextcloud'
	backup_cmd_stdout_filename "nextcloud.sql"
	command_after "#{occ} maintenance:mode --off &> /dev/null"
	user 'nextcloud'
	cron_minute 55
end