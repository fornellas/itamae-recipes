node.validate! do
  {
    cherrymusic: {
      domain: string,
      port: string,
      media_path: string,
    },
  }
end

domain = node[:cherrymusic][:domain]
cherrymusic_port = node[:cherrymusic][:port]
media_path = node[:cherrymusic][:media_path]

var_path = "/var/lib/cherrymusic"
cherrymusic_bin = "#{var_path}/.local/bin/cherrymusic"
config_dir = "#{var_path}/.config/cherrymusic"
config_path = "#{config_dir}/cherrymusic.conf"

include_recipe "../iptables"
include_recipe "../letsencrypt"
include_recipe "../nginx"

##
## Deps
##

  package "faad"
  package "flac"
  package "imagemagick"
  package "ffmpeg"
  package "lame"
  package "mpg123"
  package "opus-tools"
  package "python3"
  package "python3-pip"
  package "python3-unidecode"
  package "vorbis-tools"

##
## CherryMusic
##

  # User / Group

    group "cherrymusic"

    user "cherrymusic" do
      gid "cherrymusic"
      home var_path
      system_user true
      shell "/usr/sbin/nologin"
      create_home true
    end

  # iptables

    iptables_rule_drop_not_user "Drop not www-data user to CherryMusic" do
      users ["www-data"]
      port cherrymusic_port
    end

  # Install

    execute "pip install cherrymusic" do
      user "cherrymusic"
      not_if "test -e #{cherrymusic_bin}"
    end

    directory media_path do
      mode "775"
      owner "cherrymusic"
      group "cherrymusic"
    end

  # Configuration

    directory config_dir do
      mode "775"
      owner "cherrymusic"
      group "cherrymusic"
    end

    template config_path do
      owner "cherrymusic"
      group "cherrymusic"
      variables(
        port: cherrymusic_port,
        basedir: media_path,
      )
      notifies :restart, "service[cherrymusic]"
    end

  # Service

    template "/etc/systemd/system/cherrymusic.service" do
      mode "644"
      owner "root"
      group "root"
      variables(
        cherrymusic_bin: cherrymusic_bin
      )
      notifies :run, "execute[systemctl daemon-reload]"
    end

    execute "systemctl daemon-reload" do
      action :nothing
      user "root"
      notifies :restart, "service[cherrymusic]"
    end

    service "cherrymusic" do
      action [:enable, :start]
    end

##
## Nginx
##

  # Certificate

    letsencrypt domain

  # Auth

    remote_file "/etc/pam.d/cherrymusic" do
      mode "644"
      owner "root"
      group "root"
    end

  # Configuration

    template "/etc/nginx/sites-enabled/cherrymusic" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        cherrymusic_port: cherrymusic_port,
      )
      notifies :restart, "service[nginx]", :immediately
    end

##
## Monitoring
##

  cherrymusic_instance = "http://#{domain}/"

  prometheus_scrape_targets_blackbox_http_401 "cherrymusic" do
    targets [{hosts: [cherrymusic_instance]}]
  end

  prometheus_rules "cherrymusic" do
    alerting_rules [
      {
        alert: "CherryMusic Down",
        expr: <<~EOF,
          group(
            up{
              instance="#{cherrymusic_instance}",
              job="blackbox_http_401",
            } < 1,
          )
        EOF
      },
    ]
  end