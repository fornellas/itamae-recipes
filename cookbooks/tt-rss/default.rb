domain = "tt-rss.sigstop.co.uk"
port = "443"
php_major_version = "7"
php_minor_version = "2"
php_version = "#{php_major_version}.#{php_minor_version}"
socket_path = "/run/php/php#{php_version}-fpm-tt-rss.sock"
home_path = "/var/lib/tt-rss"
install_path = "#{home_path}/TinyTinyRSS"

##
## Deps
##

package "php#{php_version}-cli"
package "php#{php_version}-common"
package "php#{php_version}-curl"
package "php#{php_version}-fpm"
package "php#{php_version}-gd"
package "php#{php_version}-json"
package "php#{php_version}-mbstring"
package "php#{php_version}-mysql"
package "php#{php_version}-opcache"
package "php#{php_version}-xml"

include_recipe "../mysql"
include_recipe "../php-fpm"
include_recipe "../backblaze"

##
## User / Group
##

group "tt-rss"

user "tt-rss" do
  gid "tt-rss"
  home home_path
  system_user true
  shell "/usr/sbin/nologin"
  create_home true
end

##
## TinyTinyRSS
##

# TinyTinyRSS

git install_path do
  user "tt-rss"
  revision "master"
  repository "https://tt-rss.org/git/tt-rss.git"
end

# videoframes

git "#{home_path}/ttrss-videoframes" do
  user "tt-rss"
  revision "master"
  repository "https://github.com/tribut/ttrss-videoframes.git"
end

link "#{install_path}/plugins.local/videoframes" do
  user "tt-rss"
  to "#{home_path}/ttrss-videoframes/videoframes"
end

# FPM

template "/etc/php/#{php_version}/fpm/pool.d/tt-rss.conf" do
  source "templates/etc/php/fpm/pool.d/tt-rss.conf"
  mode "644"
  owner "root"
  group "root"
  variables(
    prefix: install_path,
    socket_path: socket_path,
  )
  notifies :restart, "service[php#{php_version}-fpm]"
end

# Update Daemon

template "/etc/systemd/system/tt-rss-update_daemon.service" do
  mode "644"
  owner "root"
  group "root"
  variables(install_path: install_path)
  notifies :run, "execute[systemctl daemon-reload]"
end

execute "systemctl daemon-reload" do
  action :nothing
  user "root"
  notifies :restart, "service[tt-rss-update_daemon]"
end

service "tt-rss-update_daemon" do
  action [:enable, :start]
end

##
## Nginx
##

# Let's Encrypt

include_recipe "../letsencrypt"
letsencrypt domain

# Nginx

include_recipe "../nginx"

template "/etc/nginx/sites-enabled/tt-rss" do
  mode "644"
  owner "root"
  group "root"
  variables(
    domain: domain,
    port: port,
    fpm_pool_prefix: install_path,
    socket_path: socket_path,
  )
  notifies :restart, "service[nginx]", :immediately
end

##
## Prometheus
##

prometheus_scrape_targets_blackbox_http_2xx "tt-rss" do
  targets [{ hosts: ["http://tt-rss.sigstop.co.uk/"] }]
end

##
## Backup
##

backblaze "#{node["fqdn"].tr(".", "-")}-tt-rss" do
  backup_paths [home_path]
  backup_cmd_stdout "/usr/bin/mysqldump ttrss"
  backup_cmd_stdout_filename "ttrss.sql"
  user "tt-rss"
  group "tt-rss"
  cron_hour 3
  cron_minute 40
end
