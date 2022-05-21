node.validate! do
  {
    nextcloud: {
      domain: string,
      version: string,
      php_version: string,
    },
  }
end

domain = node[:nextcloud][:domain]
nextcloud_version = node[:nextcloud][:version]
php_version = node[:nextcloud][:php_version]
php = "/usr/bin/php#{php_version}"
home_path = "/var/lib/nextcloud"
install_path = "#{home_path}/nextcloud"
first_install_ok_path = "#{install_path}/.ok"
first_config_pending_path = "#{install_path}/config/.pending.first_config"
upgrade_ok_path = "#{first_install_ok_path}.#{nextcloud_version}"
socket_path = "/run/php/php#{php_version}-fpm-nextcloud.sock"
occ = "#{php} #{install_path}/occ"

##
## Deps
##

  include_recipe "../../cookbooks/php-ppa"
  include_recipe "../../cookbooks/php-fpm"

  # https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html#prerequisites-for-manual-installation
  php_fpm php_version
  # Required
  package "php#{php_version}-common" # ctype
  package "php#{php_version}-curl"
  package "php#{php_version}-xml" # dom
  package "php#{php_version}-gd"
  package "php#{php_version}-xml" # libxml, SimpleXML, XMLReader, XMLWriter: Linux package libxml2 must be >=2.7.0
  package "php#{php_version}-mbstring"
  package "php#{php_version}-common" # posix
  package "php#{php_version}-zip"
  # Database
  package "php#{php_version}-pgsql"
  # Recommended
  package "php#{php_version}-common" # fileinfo: highly recommended, enhances file analysis performance
  package "php#{php_version}-bz2" # recommended, required for extraction of apps
  package "php#{php_version}-intl" # increases language translation performance and fixes sorting of non-ASCII characters
  # Specific apps
  package "php#{php_version}-ldap" # for LDAP integration
  package "php#{php_version}-smbclient" # SMB/CIFS integration, see SMB/CIFS
  package "php#{php_version}-common" # ftp: for FTP storage / external user authentication
  package "php#{php_version}-imap" # for external user authentication
  package "php#{php_version}-bcmath" # for passwordless login
  package "php#{php_version}-gmp" # for passwordless login
  # Specific apps (optional):
  package "php#{php_version}-gmp" # for SFTP storage
  package "php#{php_version}-common" # exif: for image rotation in pictures app
  # For enhanced server performance (optional) select one of the following memcaches:
  # PHP module apcu (>= 4.0.6)
  # PHP module memcached
  # PHP module redis (>= 2.2.6, required for Transactional File Locking)
  # For preview generation (optional):
  package "php#{php_version}-imagick" # PHP module imagick
  package "ffmpeg" # avconv or ffmpeg
  package "libreoffice" # OpenOffice or LibreOffice
  # For command line processing (optional):
  # PHP module pcntl (enables command interruption by pressing ctrl-c)
  # For command line updater (optional):
  package "php#{php_version}-common" # phar: (upgrades Nextcloud by running sudo -u www-data php /var/www/nextcloud/updater/updater.phar)

##
## User / Group
##

  group "nextcloud"

  user "nextcloud" do
  gid "nextcloud"
  home home_path
  system_user true
  shell "/usr/sbin/nologin"
  create_home true
  end

##
## Database
##

  include_recipe "../../cookbooks/postgresql"

  postgresql_database "nextcloud"

##
## Check Partial Upgrade
##

  execute 'echo "Upgrade interrupted, please fix it manually!" ; exit 1' do
    user "nextcloud"
    only_if "test -e $(dirname #{install_path})/nextcloud-old"
  end

##
## First Install
##

  # Unpack

    execute "Install" do
      command <<~EOF
        set -e
        # rm -f /tmp/nextcloud-#{nextcloud_version}.tar.bz2
        # wget https://download.nextcloud.com/server/releases/nextcloud-#{nextcloud_version}.tar.bz2 -O /tmp/nextcloud-#{nextcloud_version}.tar.bz2
        rm -rf nextcloud/
        tar jxf /tmp/nextcloud-#{nextcloud_version}.tar.bz2
        # rm -f /tmp/nextcloud-#{nextcloud_version}.tar.bz2
        # find nextcloud/ -type d -exec chmod 750 {} \\;
        # find nextcloud/ -type f -exec chmod 640 {} \\;
        touch #{first_config_pending_path}
        touch #{upgrade_ok_path}
        touch #{first_install_ok_path}
      EOF
      user "nextcloud"
      not_if "test -e #{first_install_ok_path}"
    end

  # First Config

    execute "Configure" do
      command <<~EOF
        set -e
        #{occ} maintenance:install \
          --database=pgsql \
          --database-name=nextcloud \
          --database-host=/var/run/postgresql \
          --database-user=nextcloud \
          --database-pass= \
          --database-table-space=oc_ \
          --admin-pass=FIXME \
          --no-interaction
        #{occ} config:system:set \
          trusted_domains 1 --value=#{domain}
        rm #{first_config_pending_path}
      EOF
      user "nextcloud"
      only_if "test -f #{first_config_pending_path}"
    end

##
## Upgrade
##
  
  # https://docs.nextcloud.com/server/latest/admin_manual/maintenance/upgrade.html

  execute "Upgrade" do
    command <<~EOF
      set -e

      # Set maintenance and stop things
      sudo -u nextcloud #{occ} maintenance:mode --on
      systemctl stop php#{php_version}-fpm
      crontab -u nextcloud -r

      # Rename
      cd $(dirname #{install_path})
      mv nextcloud/ nextcloud-old/

      # Donwload & unpack
      # rm -f /tmp/nextcloud-#{nextcloud_version}.tar.bz2
      # wget https://download.nextcloud.com/server/releases/nextcloud-#{nextcloud_version}.tar.bz2 -O /tmp/nextcloud-#{nextcloud_version}.tar.bz2
      tar jxf /tmp/nextcloud-#{nextcloud_version}.tar.bz2
      # rm -f /tmp/nextcloud-#{nextcloud_version}.tar.bz2

      # Move config
      mv -f nextcloud-old/config/config.php nextcloud/config/config.php

      # Move data
      rm -rf nextcloud/data/
      mv nextcloud-old/data nextcloud/

      # Move apps
      for old_app_path in nextcloud-old/apps/* ; do
        app=$(basename $old_app_path)
        if ! [ -d nextcloud/$app ] ; then
          mv $old_app_path nextcloud/apps/$app
        fi
      done

      # Move themes
      for old_theme_path in nextcloud-old/themes/* ; do
        theme=$(basename $old_theme_path)
        if ! [ -d nextcloud/$theme ] ; then
          mv $old_theme_path nextcloud/themes/$theme
        fi
      done

      # Fix ownership
      chown nextcloud.nextcloud -R nextcloud/

      # Cleanup
      rm -rf nextcloud-old/

      # Start service
      systemctl start php#{php_version}-fpm

      # Upgrade
      cd nextcloud/
      sudo -u nextcloud #{occ} upgrade
      sudo -u nextcloud #{occ} db:add-missing-columns
      sudo -u nextcloud #{occ} db:add-missing-indices
      sudo -u nextcloud #{occ} db:add-missing-primary-keys
      cd -

      sudo -u nextcloud #{occ} maintenance:mode --off
      touch #{upgrade_ok_path}
    EOF
    user "root"
    not_if "test -e #{upgrade_ok_path}"
  end

##
## Cron
##

  crontab = "*/5  *  *  *  * #{php} -f #{install_path}cron.php"
  escaped_crontab = Shellwords.shellescape(crontab)
  execute "crontab" do
    command "echo #{escaped_crontab} | crontab -u nextcloud -"
    only_if '[ "$(crontab -u nextcloud -l)" != '"#{escaped_crontab}"' ]'
  end

##
## PHP FPM
##

  template "/etc/php/#{php_version}/fpm/pool.d/nextcloud.conf" do
    source "templates/etc/php/fpm/pool.d/nextcloud.conf"
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

  # Let's Encrypt

    include_recipe "../letsencrypt"
    letsencrypt domain

  # Nginx

    include_recipe "../nginx"

    template "/etc/nginx/sites-enabled/nextcloud" do
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

  # prometheus_scrape_targets_blackbox_http_2xx "nextcloud" do
  #   targets [{ hosts: ["http://nextcloud.sigstop.co.uk/"] }]
  # end

##
## Backup
##

  # https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html

  backblaze "#{node["fqdn"].tr(".", "-")}-nextcloud" do
    command_before "#{occ} maintenance:mode --on &> /dev/null"
    backup_paths [
                   "#{install_path}/apps/",
                   "#{install_path}/config/",
                   "#{install_path}/data/",
                   "#{install_path}/themes/",
                 ]
    backup_cmd_stdout "pg_dump nextcloud"
    backup_cmd_stdout_filename "nextcloud.sql"
    command_after "#{occ} maintenance:mode --off &> /dev/null"
    user "nextcloud"
    group "nextcloud"
    cron_hour 6
    cron_minute 30
    bin_path home_path
  end
