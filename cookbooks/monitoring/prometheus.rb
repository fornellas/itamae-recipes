node.validate! do
  {
    prometheus: {
      version: string,
      arch: string,
      domain: string,
      port: string,
      storage_tsdb_retention_time: string,
      storage_tsdb_retention_size: string,
    },
    alertmanager: {
      web_port: string,
    }
  }
end

version = node[:prometheus][:version]
arch = node[:prometheus][:arch]
domain = node[:prometheus][:domain]
web_listen_port = node[:prometheus][:port]
retention_time = node[:prometheus][:storage_tsdb_retention_time]
retention_size = node[:prometheus][:storage_tsdb_retention_size]

var_path = "/var/lib/prometheus"
tar_gz_url = "https://github.com/prometheus/prometheus/releases/download/v#{version}/prometheus-#{version}.linux-#{arch}.tar.gz"

include_recipe "../backblaze"
include_recipe "../nginx"
include_recipe "../letsencrypt"

##
## prometheus
##

  # User / Group

    group "prometheus"

    user "prometheus" do
      gid "prometheus"
      home var_path
      system_user true
      shell "/usr/sbin/nologin"
      create_home true
    end

  # Install

    execute "wget -O prometheus.tar.gz #{tar_gz_url} && tar zxf prometheus.tar.gz && chown root.root -R prometheus-#{version}.linux-#{arch} && rm -rf /opt/prometheus && mv prometheus-#{version}.linux-#{arch} /opt/prometheus && touch /opt/prometheus/.#{version}.ok" do
      user "root"
      cwd "/tmp"
      not_if "test -f /opt/prometheus/.#{version}.ok"
    end

  # Configuration

    directory "/etc/prometheus" do
      owner "root"
      group "root"
      mode "755"
    end

    directory "/etc/prometheus/blackbox_http_2xx.d" do
      owner "root"
      group "root"
      mode "755"
    end
    directory "/etc/prometheus/blackbox_http_401.d" do
      owner "root"
      group "root"
      mode "755"
    end
    directory "/etc/prometheus/blackbox_ssh_banner.d" do
      owner "root"
      group "root"
      mode "755"
    end

    directory "/etc/prometheus/rules.d" do
      owner "root"
      group "root"
      mode "755"
    end

    directory "/etc/prometheus/node.d" do
      owner "root"
      group "root"
      mode "755"
    end

    template "/etc/prometheus/prometheus.yml" do
      mode "644"
      owner "root"
      group "root"
      variables(
        blackbox_exporter_port: node[:blackbox_exporter][:port],
        alertmanager_port: node[:alertmanager][:web_port],
      )
      notifies :restart, "service[prometheus]"
    end

  # Service

    template "/etc/systemd/system/prometheus.service" do
      mode "644"
      owner "root"
      group "root"
      variables(
        install_path: "/opt/prometheus",
        config_file: "/etc/prometheus/prometheus.yml",
        storage_tsdb_path: "#{var_path}/tsdb",
        web_listen_address: "127.0.0.1:#{web_listen_port}",
        web_external_url: "https://#{domain}/",
        storage_tsdb_retention_time: retention_time,
        storage_tsdb_retention_size: retention_size,
      )
      notifies :run, "execute[systemctl daemon-reload]"
    end

    execute "systemctl daemon-reload" do
      action :nothing
      user "root"
      notifies :restart, "service[prometheus]"
    end

    service "prometheus" do
      action [:enable, :start]
    end

  # Backup

    backblaze "#{node["fqdn"].tr(".", "-")}-prometheus" do
      command_before "sudo -u prometheus /usr/bin/curl -s -XPOST http://localhost:#{web_listen_port}/api/v1/admin/tsdb/snapshot > /dev/null"
      backup_paths ["#{var_path}/tsdb/snapshots"]
      command_after "/bin/rm -rf #{var_path}/tsdb/snapshots/*"
      cron_hour 6
      cron_minute 0
      user "prometheus"
      group "prometheus"
      bin_path var_path
    end

##
## Nginx
##

  # Certificate

    letsencrypt domain

  # Auth

    remote_file "/etc/pam.d/prometheus" do
      mode "644"
      owner "root"
      group "root"
    end

  # Configuration

    template "/etc/nginx/sites-enabled/prometheus" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        prometheus_port: web_listen_port,
      )
      notifies :restart, "service[nginx]", :immediately
    end