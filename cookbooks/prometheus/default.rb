home_path = "/var/lib/prometheus"
domain = "prometheus.sigstop.co.uk"
web_listen_port = "9090"
nginx_port = "443"
version = "2.31.0"
retention_time = "10y"
retention_size = "15GB"
arch = "armv7"
tar_gz_url = "https://github.com/prometheus/prometheus/releases/download/v#{version}/prometheus-#{version}.linux-#{arch}.tar.gz"

include_recipe "../backblaze"
include_recipe "../iptables"

##
## blackbox_exporter
##

include_recipe "../../cookbooks/blackbox_exporter"

directory "/etc/prometheus/blackbox_http_2xx.d" do
  owner "root"
  group "root"
  mode "755"
end

# Usage
#
# prometheus_scrape_targets_blackbox_http_2xx "test" do
#   targets [
#     {
#       # The targets specified by the static config.
#       hosts: [
#         "host1:123",
#         "host2:456",
#       ],
#       # Labels assigned to all metrics scraped from the targets.
#       # Optional
#       labels: {
#         a: "b",
#         c: "d",
#       },
#     }
#   ]
# end
define(
  :prometheus_scrape_targets_blackbox_http_2xx,
  targets: [],
) do
  name = params[:name]
  targets = params[:targets]

  rule_path = "/etc/prometheus/blackbox_http_2xx.d/#{name}.yml"

  template rule_path do
    mode "644"
    owner "root"
    group "root"
    source "templates/etc/prometheus/file_sd.d/template.yml"
    variables(
      targets: targets,
    )
  end
end

directory "/etc/prometheus/blackbox_http_401.d" do
  owner "root"
  group "root"
  mode "755"
end

# Usage
#
# prometheus_scrape_targets_blackbox_http_401 "test" do
#   targets [
#     {
#       # The targets specified by the static config.
#       hosts: [
#         "host1:123",
#         "host2:456",
#       ],
#       # Labels assigned to all metrics scraped from the targets.
#       # Optional
#       labels: {
#         a: "b",
#         c: "d",
#       },
#     }
#   ]
# end
define(
  :prometheus_scrape_targets_blackbox_http_401,
  targets: [],
) do
  name = params[:name]
  targets = params[:targets]

  rule_path = "/etc/prometheus/blackbox_http_401.d/#{name}.yml"

  template rule_path do
    mode "644"
    owner "root"
    group "root"
    source "templates/etc/prometheus/file_sd.d/template.yml"
    variables(
      targets: targets,
    )
  end
end

directory "/etc/prometheus/blackbox_ssh_banner.d" do
  owner "root"
  group "root"
  mode "755"
end

# Usage
#
# prometheus_scrape_targets_blackbox_ssh_banner "test" do
#   targets [
#     {
#       # The targets specified by the static config.
#       hosts: [
#         "host1:123",
#         "host2:456",
#       ],
#       # Labels assigned to all metrics scraped from the targets.
#       # Optional
#       labels: {
#         a: "b",
#         c: "d",
#       },
#     }
#   ]
# end
define(
  :prometheus_scrape_targets_blackbox_ssh_banner,
  targets: [],
) do
  name = params[:name]
  targets = params[:targets]

  rule_path = "/etc/prometheus/blackbox_ssh_banner.d/#{name}.yml"

  template rule_path do
    mode "644"
    owner "root"
    group "root"
    source "templates/etc/prometheus/file_sd.d/template.yml"
    variables(
      targets: targets,
    )
  end
end

##
## Prometheus
##

# User / Group

group "prometheus"

user "prometheus" do
  gid "prometheus"
  home home_path
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

directory "/etc/prometheus/rules.d" do
  owner "root"
  group "root"
  mode "755"
end

# Usage:
#
# prometheus_rules "test" do
#   # How often rules in the group are evaluated.
#   # Optional.
#   interval "1m"
#   # Limit the number of alerts an alerting rule and series a recording
#   # rule can produce. 0 is no limit.
#   # Optional.
#   limit 0
#   # Alerting Rules
#   alerting_rules [
#     {
#       # The name of the alert. Must be a valid label value.
#       # Required.
#       alert: "alert name",
#       # The PromQL expression to evaluate. Every evaluation cycle this is
#       # evaluated at the current time, and all resultant time series become
#       # pending/firing alerts.
#       # Required.
#       expr: "up < 1",
#       # Alerts are considered firing once they have been returned for this long.
#       # Alerts which have not yet fired for long enough are considered pending.
#       # Optional.
#       for: "3m",
#       # Labels to add or overwrite for each alert.
#       # Optional.
#       labels: {
#         a: "b",
#         c: "d",
#       },
#       # Annotations to add to each alert.
#       # Optional.
#       annotations: {
#         e: "f",
#         g: "h",
#       },
#     },
#   ]
#   # Recording Rules
#   recording_rules [
#     {
#       # The name of the time series to output to. Must be a valid metric name.
#       # Required.
#       record: "record name",
#       # The PromQL expression to evaluate. Every evaluation cycle this is
#       # evaluated at the current time, and the result recorded as a new set of
#       # time series with the metric name as given by 'record'.
#       # Required.
#       expr: "up < 1",
#       # Labels to add or overwrite before storing the result.
#       # Optional.
#       labels: {
#         a: "b",
#         c: "d",
#       },
#     },
#   ]
# end
define(
  :prometheus_rules,
  interval: nil,
  limit: nil,
  alerting_rules: [],
  recording_rules: [],
) do
  name = params[:name]
  interval = params[:interval]
  limit = params[:limit]
  alerting_rules = params[:alerting_rules]
  recording_rules = params[:recording_rules]

  rule_path = "/etc/prometheus/rules.d/#{name}.yml"

  template rule_path do
    mode "644"
    owner "root"
    group "root"
    source "templates/etc/prometheus/rules.d/template.yml"
    variables(
      group_name: name,
      interval: interval,
      limit: limit,
      alerting_rules: alerting_rules,
      recording_rules: recording_rules,
    )

    notifies :restart, "service[prometheus]"
  end
end

directory "/etc/prometheus/node.d" do
  owner "root"
  group "root"
  mode "755"
end

# Usage
#
# prometheus_scrape_targets "test" do
#   targets [
#     {
#       # The targets specified by the static config.
#       hosts: [
#         "host1:123",
#         "host2:456",
#       ],
#       # Labels assigned to all metrics scraped from the targets.
#       # Optional
#       labels: {
#         a: "b",
#         c: "d",
#       },
#     }
#   ]
# end
define(
  :prometheus_scrape_targets,
  targets: [],
) do
  name = params[:name]
  targets = params[:targets]

  rule_path = "/etc/prometheus/node.d/#{name}.yml"

  template rule_path do
    mode "644"
    owner "root"
    group "root"
    source "templates/etc/prometheus/file_sd.d/template.yml"
    variables(
      targets: targets,
    )
  end
end

prometheus_scrape_targets "prometheus" do
  targets [
    {
      hosts: ["localhost:#{web_listen_port}"],
      labels: {
        instance: "odroid.local:#{web_listen_port}",
        exporter: "prometheus",
      },
    },
  ]
end

prometheus_scrape_targets "blackbox_exporter" do
  targets [
    {
      hosts: ["localhost:9115"],
      labels: {
        instance: "odroid.local:9115",
        exporter: "blackbox_exporter",
      },
    },
  ]
end

prometheus_rules "blackbox_exporter" do
  alerting_rules [
    {
      alert: "BlackboxExporterDown",
      expr: 'up{instance="odroid.local:9115"} < 1',
    },
  ]
end

remote_file "/etc/prometheus/prometheus.yml" do
  mode "644"
  owner "root"
  group "root"
  notifies :restart, "service[prometheus]"
end

# Backup

backblaze "#{node["fqdn"].tr(".", "-")}-prometheus" do
  command_before "sudo -u prometheus /usr/bin/curl -s -XPOST http://localhost:#{web_listen_port}/api/v1/admin/tsdb/snapshot > /dev/null"
  backup_paths ["#{home_path}/tsdb/snapshots"]
  command_after "/bin/rm -rf #{home_path}/tsdb/snapshots/*"
  cron_hour 6
  cron_minute 0
  user "prometheus"
  group "prometheus"
  bin_path home_path
end

# iptables

iptables_rule_drop_not_user "Drop not www-data|grafana|prometheus user to Prometheus" do
  users ["www-data", "grafana", "prometheus"]
  port web_listen_port
end

# Service

template "/etc/systemd/system/prometheus.service" do
  mode "644"
  owner "root"
  group "root"
  variables(
    install_path: "/opt/prometheus",
    config_file: "/etc/prometheus/prometheus.yml",
    storage_tsdb_path: "#{home_path}/tsdb",
    web_listen_address: "127.0.0.1:#{web_listen_port}",
    web_external_url: "http://#{domain}/",
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

##
## Let's Encrypt
##

include_recipe "../letsencrypt"

letsencrypt domain

##
## Nginx
##

include_recipe "../nginx"

package "libnginx-mod-http-auth-pam"

remote_file "/etc/pam.d/prometheus" do
  mode "644"
  owner "root"
  group "root"
end

template "/etc/nginx/sites-enabled/prometheus" do
  mode "644"
  owner "root"
  group "root"
  variables(
    domain: domain,
    port: nginx_port,
    prometheus_port: web_listen_port,
  )
  notifies :restart, "service[nginx]", :immediately
end

##
## Prometheus
##

prometheus_scrape_targets_blackbox_http_401 "prometheus" do
  targets [{ hosts: ["http://prometheus.sigstop.co.uk/"] }]
end

prometheus_rules "prometheus" do
  alerting_rules [
    {
      alert: "PrometheusDown",
      expr: 'up{instance="http://prometheus.sigstop.co.uk/"} < 1',
    },
    {
      alert: "PrometheusNotificationsDropped",
      expr: 'prometheus_notifications_dropped_total{instance="odroid.local:9090"} > 0',
    },
    {
      alert: "PrometheusNotificationsErrors",
      expr: 'prometheus_notifications_errors_total{instance="odroid.local:9090"} > 0',
    },
    {
      alert: "PrometheusSdFailedConfigs",
      expr: 'prometheus_sd_failed_configs{instance="odroid.local:9090"} > 0',
    },
    {
      alert: "PrometheusSdFileReadErrors",
      expr: 'prometheus_sd_file_read_errors_total{instance="odroid.local:9090"} > 0',
    },
  ]
end
