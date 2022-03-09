node.validate! do
  {
    alertmanager: {
      version: string,
      arch: string,
      domain: string,
      web_port: string,
      cluster_port: string,
      discord_webhook: string,
    },
  }
end

version = node[:alertmanager][:version]
arch = node[:alertmanager][:arch]
domain = node[:alertmanager][:domain]
web_listen_port = node[:alertmanager][:web_port]
cluster_listen_port = node[:alertmanager][:cluster_port]

var_path = "/var/lib/alertmanager"
tar_gz_url = "https://github.com/prometheus/alertmanager/releases/download/v#{version}/alertmanager-#{version}.linux-#{arch}.tar.gz"

include_recipe "../backblaze"
include_recipe "../iptables"
include_recipe "../nginx"
include_recipe "../letsencrypt"

##
## alertmanager
##

  # User / Group

    group "alertmanager"

    user "alertmanager" do
      gid "alertmanager"
      home var_path
      system_user true
      shell "/usr/sbin/nologin"
      create_home true
    end

  # Install

    execute "wget -O alertmanager.tar.gz #{tar_gz_url} && tar zxf alertmanager.tar.gz && chown root.root -R alertmanager-#{version}.linux-#{arch} && rm -rf /opt/alertmanager && mv alertmanager-#{version}.linux-#{arch} /opt/alertmanager && touch /opt/alertmanager/.#{version}.ok" do
      user "root"
      cwd "/tmp"
      not_if "test -f /opt/alertmanager/.#{version}.ok"
    end

  # Configuration

    directory "/etc/alertmanager" do
      owner "root"
      group "root"
      mode "755"
    end

    discord_webhook = node[:alertmanager][:discord_webhook]

    template "/etc/alertmanager/alertmanager.yml" do
      mode "644"
      owner "root"
      group "root"
      variables(
        slack_webhook_url: "#{discord_webhook}/slack",
      )
      notifies :restart, "service[alertmanager]"
    end

  # Service

    template "/etc/systemd/system/alertmanager.service" do
      mode "644"
      owner "root"
      group "root"
      variables(
        install_path: "/opt/alertmanager",
        config_file: "/etc/alertmanager/alertmanager.yml",
        storage_path: var_path,
        web_listen_address: "127.0.0.1:#{web_listen_port}",
        web_external_url: "https://#{domain}/",
        cluster_listen_address: "127.0.0.1:#{cluster_listen_port}",
      )
      notifies :run, "execute[systemctl daemon-reload]"
    end

    execute "systemctl daemon-reload" do
      action :nothing
      user "root"
      notifies :restart, "service[alertmanager]"
    end

    service "alertmanager" do
      action [:enable, :start]
    end

  # Backup

    backblaze "#{node["fqdn"].tr(".", "-")}-alertmanager" do
      backup_paths [var_path]
      cron_hour 6
      cron_minute 15
      user "alertmanager"
      group "alertmanager"
      bin_path var_path
    end

##
## Nginx
##

  # Certificate
  
    letsencrypt domain

  # Auth

    remote_file "/etc/pam.d/alertmanager" do
      mode "644"
      owner "root"
      group "root"
    end

  # Configuration

    template "/etc/nginx/sites-enabled/alertmanager" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        alertmanager_port: web_listen_port,
      )
      notifies :restart, "service[nginx]", :immediately
    end