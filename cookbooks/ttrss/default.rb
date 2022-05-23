# Extracted from: https://git.tt-rss.org/fox/ttrss-docker-compose.git/tree/app/Dockerfile?id=46a7d193742d24d3a910ef910ac3b6c940185975

node.validate! do
  {
    ttrss: {
      php_version: string,
      domain: string,
    },
  }
end

php_version = node[:ttrss][:php_version]
php = "/usr/bin/php#{php_version}"
ttrss_git_repo = "https://git.tt-rss.org/fox/tt-rss.git"
home_path = "/var/lib/ttrss"
install_path = "#{home_path}/ttrss"
plugins_local_path = "#{install_path}/plugins.local"
ttrss_nginx_xaccel_repo = "https://git.tt-rss.org/fox/ttrss-nginx-xaccel.git"
videoframes_repo = "https://github.com/tribut/ttrss-videoframes.git"

##
## Deps
##

  include_recipe "../../cookbooks/php-ppa"
  include_recipe "../../cookbooks/php-fpm"

  php_fpm php_version
  package "php#{php_version}-common" # pdo
  package "php#{php_version}-gd"
  package "php#{php_version}-pgsql" # pgsql, pdo_pgsql
  package "php#{php_version}-mbstring"
  package "php#{php_version}-intl"
  package "php#{php_version}-xml" # xml, dom
  package "php#{php_version}-curl"
  package "php#{php_version}-common" # tokenizer
  package "php#{php_version}-common" # fileinfo
  package "php#{php_version}-common" # iconv
  package "php#{php_version}-common" # posix
  package "php#{php_version}-zip"
  package "php#{php_version}-common" # exif
  package "php#{php_version}-xdebug" # pecl-xdebug

##
## User / Group
##

  group "ttrss"

  user "ttrss" do
    gid "ttrss"
    home home_path
    system_user true
    shell "/usr/sbin/nologin"
    create_home true
  end


##
## Database
##

  include_recipe "../../cookbooks/postgresql"

  postgresql_database "ttrss"

##
## Install
##

  # tt-rss

    git install_path do
      user "ttrss"
      revision "master"
      repository ttrss_git_repo
    end

  # ttrss-nginx-xaccel

    git "#{home_path}/nginx_xaccel" do
      user "ttrss"
      revision "master"
      repository ttrss_nginx_xaccel_repo
    end

    link "#{plugins_local_path}/nginx_xaccel" do
      user "ttrss"
      to "#{install_path}/nginx_xaccel"
    end

  # videoframes

    git "#{home_path}/ttrss-videoframes" do
      user "ttrss"
      revision "master"
      repository videoframes_repo
    end

    link "#{plugins_local_path}/ttrss-videoframes" do
      user "ttrss"
      to "#{install_path}/ttrss-videoframes"
    end

##
## Update Schema
##

# php8 ./update.php --update-schema=force-yes
# only_if ./.git/logs/HEAD is newer than update ok

##
## Updater Daemon
##

  # template "/etc/systemd/system/ttrss-update_daemon.service" do
  #   mode "644"
  #   owner "root"
  #   group "root"
  #   variables(
  #     php: php,
  #     install_path: install_path,
  #   )
  #   notifies :run, "execute[systemctl daemon-reload]"
  # end

  # execute "systemctl daemon-reload" do
  #   action :nothing
  #   user "root"
  #   notifies :restart, "service[ttrss-update_daemon]"
  # end

  # service "tt-rss-update_daemon" do
  #   action [:enable, :start]
  # end

##
## PHP FPM
##

  template "/etc/php/#{php_version}/fpm/pool.d/ttrss.conf" do
    source "templates/etc/php/fpm/pool.d/ttrss.conf"
    mode "644"
    owner "root"
    group "root"
    variables(
      prefix: install_path,
      socket_path: socket_path,
    )
    notifies :restart, "service[php#{php_version}-fpm]"
  end

##
## Nginx
##

  # # Let's Encrypt

  #   include_recipe "../letsencrypt"
  #   letsencrypt domain

  # # Nginx

  #   include_recipe "../nginx"

  # # Auth

  #   remote_file "/etc/pam.d/ttrss" do
  #     mode "644"
  #     owner "root"
  #     group "root"
  #   end

  #   template "/etc/nginx/sites-enabled/ttrss" do
  #     mode "644"
  #     owner "root"
  #     group "root"
  #     variables(
  #       domain: domain,
  #       fpm_pool_prefix: install_path,
  #       socket_path: socket_path,
  #     )
  #     notifies :restart, "service[nginx]", :immediately
  #   end

##
## Prometheus
##

  # prometheus_scrape_targets_blackbox_http_2xx "ttrss" do
  #   targets [{ hosts: ["http://tt-rss.sigstop.co.uk/"] }]
  # end

##
## Backup
##

  # backblaze "#{node["fqdn"].tr(".", "-")}-ttrss" do
  #   backup_paths [home_path]
  #   backup_cmd_stdout "/usr/bin/mysqldump ttrss"
  #   backup_cmd_stdout_filename "ttrss.sql"
  #   user "tt-rss"
  #   group "tt-rss"
  #   cron_hour 3
  #   cron_minute 40
  # end

###########################################3

# domain = "tt-rss.sigstop.co.uk"
# port = "443"
# php_major_version = "7"
# php_minor_version = "2"
# php_version = "#{php_major_version}.#{php_minor_version}"
# socket_path = "/run/php/php#{php_version}-fpm-tt-rss.sock"
# home_path = "/var/lib/tt-rss"
# install_path = "#{home_path}/TinyTinyRSS"

# ##
# ## Deps
# ##

# package "php#{php_version}-cli"
# package "php#{php_version}-common"
# package "php#{php_version}-curl"
# package "php#{php_version}-fpm"
# package "php#{php_version}-gd"
# package "php#{php_version}-json"
# package "php#{php_version}-mbstring"
# package "php#{php_version}-mysql"
# package "php#{php_version}-opcache"
# package "php#{php_version}-xml"

# include_recipe "../mysql"
# include_recipe "../php-fpm"
# include_recipe "../backblaze"

# ##
# ## User / Group
# ##

# group "tt-rss"

# user "tt-rss" do
#   gid "tt-rss"
#   home home_path
#   system_user true
#   shell "/usr/sbin/nologin"
#   create_home true
# end

# ##
# ## TinyTinyRSS
# ##

# # TinyTinyRSS

# git install_path do
#   user "tt-rss"
#   revision "master"
#   repository "https://tt-rss.org/git/tt-rss.git"
# end

# # videoframes

# git "#{home_path}/ttrss-videoframes" do
#   user "tt-rss"
#   revision "master"
#   repository "https://github.com/tribut/ttrss-videoframes.git"
# end

# link "#{install_path}/plugins.local/videoframes" do
#   user "tt-rss"
#   to "#{home_path}/ttrss-videoframes/videoframes"
# end

# # FPM

# template "/etc/php/#{php_version}/fpm/pool.d/tt-rss.conf" do
#   source "templates/etc/php/fpm/pool.d/tt-rss.conf"
#   mode "644"
#   owner "root"
#   group "root"
#   variables(
#     prefix: install_path,
#     socket_path: socket_path,
#   )
#   notifies :restart, "service[php#{php_version}-fpm]"
# end

# # Update Daemon

# template "/etc/systemd/system/tt-rss-update_daemon.service" do
#   mode "644"
#   owner "root"
#   group "root"
#   variables(install_path: install_path)
#   notifies :run, "execute[systemctl daemon-reload]"
# end

# execute "systemctl daemon-reload" do
#   action :nothing
#   user "root"
#   notifies :restart, "service[tt-rss-update_daemon]"
# end

# service "tt-rss-update_daemon" do
#   action [:enable, :start]
# end

# ##
# ## Nginx
# ##

# # Let's Encrypt

# include_recipe "../letsencrypt"
# letsencrypt domain

# # Nginx

# include_recipe "../nginx"

# template "/etc/nginx/sites-enabled/tt-rss" do
#   mode "644"
#   owner "root"
#   group "root"
#   variables(
#     domain: domain,
#     port: port,
#     fpm_pool_prefix: install_path,
#     socket_path: socket_path,
#   )
#   notifies :restart, "service[nginx]", :immediately
# end

# ##
# ## Prometheus
# ##

# prometheus_scrape_targets_blackbox_http_2xx "tt-rss" do
#   targets [{ hosts: ["http://tt-rss.sigstop.co.uk/"] }]
# end

# ##
# ## Backup
# ##

# backblaze "#{node["fqdn"].tr(".", "-")}-tt-rss" do
#   backup_paths [home_path]
#   backup_cmd_stdout "/usr/bin/mysqldump ttrss"
#   backup_cmd_stdout_filename "ttrss.sql"
#   user "tt-rss"
#   group "tt-rss"
#   cron_hour 3
#   cron_minute 40
# end
