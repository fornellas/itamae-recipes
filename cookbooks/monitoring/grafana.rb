node.validate! do
  {
    grafana: {
      version: string,
      arch: string,
      domain: string,
      port: string,
      dashboard_alerts_history_id: string,
      org_id: string,
    },
  }
end

version = node[:grafana][:version]
domain = node[:grafana][:domain]
grafana_port = node[:grafana][:port]
var_path = "/var/lib/grafana"

include_recipe "../iptables"
include_recipe "../backblaze"
include_recipe "../nginx"
include_recipe "../letsencrypt"

##
## Grafana
##

  # User / Group

    group "grafana"

    user "grafana" do
      gid "grafana"
      home var_path
      system_user true
      shell "/usr/sbin/nologin"
      create_home true
    end

  # Install

    execute "Install Grafana" do
      command "wget -O /tmp/grafana.deb https://dl.grafana.com/oss/release/grafana_#{version}_#{node[:grafana][:arch]}.deb && dpkg -i /tmp/grafana.deb && rm -f /tmp/grafana.deb"
      not_if "/usr/bin/test \"$(dpkg -s grafana | gawk '/^Version: /{print $2}')\" = \"#{version}\""
    end

  # Configuration

    remote_file "/etc/grafana/grafana.ini" do
      mode "640"
      owner "root"
      group "grafana"
      notifies :restart, "service[grafana-server]"
    end

  # Service

    service "grafana-server" do
      action [:enable, :start]
    end

  # Backup

    package "sqlite3"

    backblaze "#{node["fqdn"].tr(".", "-")}-grafana" do
      backup_paths [var_path]
      backup_exclude ["grafana.db"]
      backup_cmd_stdout "sqlite3 #{var_path}/grafana.db .dump"
      backup_cmd_stdout_filename "grafana.db"
      cron_hour 5
      cron_minute 30
      user "grafana"
      group "grafana"
      bin_path var_path
    end

##
## Nginx
##

  # Certificate

    letsencrypt domain

  # Auth

    remote_file "/etc/pam.d/grafana" do
      mode "644"
      owner "root"
      group "root"
    end

  # Configuration

    template "/etc/nginx/sites-enabled/grafana" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        grafana_port: grafana_port,
      )
      notifies :restart, "service[nginx]", :immediately
    end