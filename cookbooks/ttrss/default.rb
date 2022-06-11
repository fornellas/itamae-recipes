# Extracted from: https://git.tt-rss.org/fox/ttrss-docker-compose.git/tree/app/Dockerfile?id=46a7d193742d24d3a910ef910ac3b6c940185975

node.validate! do
  {
    ttrss: {
      php_version: string,
      domain: string,
    },
  }
end

domain = node[:ttrss][:domain]
php_version = node[:ttrss][:php_version]
php = "/usr/bin/php#{php_version}"
ttrss_git_repo = "https://git.tt-rss.org/fox/tt-rss.git"
home_path = "/var/lib/ttrss"
install_path = "#{home_path}/ttrss"
plugins_local_path = "#{install_path}/plugins.local"
ttrss_nginx_xaccel_repo = "https://git.tt-rss.org/fox/ttrss-nginx-xaccel.git"
videoframes_repo = "https://github.com/tribut/ttrss-videoframes.git"
data_migration_repo = "https://git.tt-rss.org/fox/ttrss-data-migration.git"
socket_path = "/run/php/php#{php_version}-fpm-ttrss.sock"
# https://tt-rss.org/wiki/GlobalConfig
env_config = {
  "TTRSS_DB_TYPE": "pgsql",
  "TTRSS_DB_HOST": "/var/run/postgresql",
  "TTRSS_DB_USER": "ttrss",
  "TTRSS_DB_NAME": "ttrss",
  "TTRSS_SELF_URL_PATH": "https://tt-rss.sigstop.co.uk/",
  "TTRSS_PHP_EXECUTABLE": php,
  "TTRSS_PLUGINS": "auth_remote, nginx_xaccel, videoframes, data_migration, swap_navigation",
  # https://git.tt-rss.org/fox/ttrss-nginx-xaccel.git/tree/README.md
  "TTRSS_NGINX_XACCEL_PREFIX": "/",
}

shell_env_lines = []
env_config.each_pair do |key, value|
  shell_env_lines << "#{key}=#{Shellwords.escape value}"
end
shell_env = shell_env_lines.join(" ")

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
      to "#{home_path}/nginx_xaccel"
    end

  # videoframes

    git "#{home_path}/ttrss-videoframes" do
      user "ttrss"
      revision "master"
      repository videoframes_repo
    end

    link "#{plugins_local_path}/videoframes" do
      user "ttrss"
      to "#{home_path}/ttrss-videoframes/videoframes"
    end

  # ttrss-data-migration

    git "#{home_path}/data_migration" do
      user "ttrss"
      revision "master"
      repository data_migration_repo
    end

    link "#{plugins_local_path}/data_migration" do
      user "ttrss"
      to "#{home_path}/data_migration"
    end

  # swap_navigation

    directory "#{plugins_local_path}/swap_navigation" do
      owner "ttrss"
      group "ttrss"
      mode "755"
    end

    remote_file "#{plugins_local_path}/swap_navigation/init.php" do
      mode "644"
      owner "ttrss"
      group "ttrss"
    end

##
## Update Schema
##

  schema_update_ok_path = "#{home_path}/.schema_update_ok"


  execute "Update schema" do
    command <<~EOF
      set -e
      #{shell_env} #{php} #{install_path}/update.php --update-schema=force-yes
      touch #{schema_update_ok_path}
    EOF
    user "ttrss"
    not_if "test #{schema_update_ok_path} -nt #{install_path}/.git/logs/HEAD"
  end

##
## Updater Daemon
##

  template "/etc/systemd/system/ttrss-update_daemon.service" do
    mode "644"
    owner "root"
    group "root"
    variables(
      env: shell_env,
      php: php,
      install_path: install_path,
    )
    notifies :run, "execute[systemctl daemon-reload]"
  end

  execute "systemctl daemon-reload" do
    action :nothing
    user "root"
    notifies :restart, "service[ttrss-update_daemon]"
  end

  service "ttrss-update_daemon" do
    action [:enable, :start]
  end

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
      env: env_config
    )
    notifies :restart, "service[php#{php_version}-fpm]"
  end

##
## Nginx
##

  # Let's Encrypt

    include_recipe "../letsencrypt"
    letsencrypt domain

  # Nginx

    include_recipe "../nginx"

  # Auth

    remote_file "/etc/pam.d/ttrss" do
      mode "644"
      owner "root"
      group "root"
    end

    template "/etc/nginx/sites-enabled/ttrss" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        fpm_pool_prefix: install_path,
        socket_path: socket_path,
      )
      notifies :restart, "service[nginx]", :immediately
    end

##
## Prometheus
##

  include_recipe "../../cookbooks/monitoring"

  ttrss_instance = "http://#{domain}/"

  prometheus_scrape_targets_blackbox_http_2xx "ttrss" do
    targets [{ hosts: [ttrss_instance] }]
  end

  prometheus_rules "ttrss" do
    alerting_rules [
      {
        alert: "TT-RSS Down",
        expr: <<~EOF,
          group(
            up{
              instance="#{ttrss_instance}",
              job="blackbox_http_2xx",
            } < 1
          )
        EOF
      },
    ]
  end

##
## Backup
##

  backblaze "#{node["fqdn"].tr(".", "-")}-ttrss" do
    backup_paths [home_path]
    backup_cmd_stdout "pg_dump ttrss"
    backup_cmd_stdout_filename "ttrss.sql"
    user "ttrss"
    group "ttrss"
    bin_path home_path
  end