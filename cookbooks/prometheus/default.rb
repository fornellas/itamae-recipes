node.validate! do
  {
    prometheus: {
      version: string,
      arch: string,
      domain: string,
      port: string,
      storage_tsdb_retention_time: string,
      storage_tsdb_retention_size: string,
      local_http_users: optional(array_of(string)),
    },
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
include_recipe "../iptables"

##
## prometheus
##

  # blackbox_exporter

    include_recipe "blackbox_exporter"

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
        alertmanager_port: node[:alertmanager][:port],
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
      action :enable
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

  # Install

    include_recipe "../nginx"

  # Certificate

    include_recipe "../letsencrypt"

    letsencrypt domain

  # Auth

    package "libnginx-mod-http-auth-pam"

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

##
## Defines
##

  include_recipe "defines"

##
## Scrape Targets
##

  # blackbox_exporter

    prometheus_scrape_targets "blackbox_exporter" do
      targets [
        {
          hosts: ["localhost:9115"],
          labels: {
            instance: "#{node["fqdn"]}:9115",
            exporter: "blackbox_exporter",
          },
        },
      ]
    end

  # prometheus

    prometheus_scrape_targets_blackbox_http_401 "prometheus" do
      targets [
        {
          hosts: [
            "http://#{domain}/"
          ]
        }
      ]
    end

    prometheus_scrape_targets "prometheus" do
      targets [
        {
          hosts: ["localhost:#{web_listen_port}"],
          labels: {
            instance: "#{node["fqdn"]}:#{web_listen_port}",
            exporter: "prometheus",
          },
        },
      ]
    end

##
## Rules & alerts
##

  # blackbox_exporter

    prometheus_rules "blackbox_exporter" do
      alerting_rules [
        {
          alert: "BlackboxExporterDown",
          expr: 'up{instance="'"#{node["fqdn"]}"':9115"} < 1',
        },
      ]
    end

  # prometheus

    prometheus_rules "prometheus" do
      alerting_rules [
        {
          alert: "PrometheusDown",
          expr: 'up{instance="http://prometheus.sigstop.co.uk/"} < 1',
        },
        {
          alert: "PrometheusNotificationsDropped",
          expr: 'rate(prometheus_notifications_dropped_total{instance="'"#{node["fqdn"]}"':9090"}[5m]) > 0',
        },
        {
          alert: "PrometheusNotificationsErrors",
          expr: 'rate(prometheus_notifications_errors_total{instance="'"#{node["fqdn"]}"':9090"}[5m]) > 0',
        },
        {
          alert: "PrometheusSdFailedConfigs",
          expr: 'prometheus_sd_failed_configs{instance="'"#{node["fqdn"]}"':9090"} > 0',
        },
        {
          alert: "PrometheusSdFileReadErrors",
          expr: 'rate(prometheus_sd_file_read_errors_total{instance="'"#{node["fqdn"]}"':9090"}[5m]) > 0',
        },
      ]
    end

##
## iptables
##

  # blackbox_exporter

    iptables_rule_drop_not_user "Drop not prometheus user to BlackboxExporter" do
      users ["prometheus"]
      port node[:blackbox_exporter][:port]
    end

  # prometheus

    iptables_rule_drop_not_user "Drop not www-data|grafana|node[:prometheus][:local_http_users] user to Prometheus" do
      users ["www-data", "prometheus"] + node[:prometheus][:local_http_users]
      port web_listen_port
    end