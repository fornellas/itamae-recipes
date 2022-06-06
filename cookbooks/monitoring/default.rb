include_recipe "prometheus"
include_recipe "blackbox_exporter"
include_recipe "alertmanager"
include_recipe "grafana"
include_recipe "../iptables"

##
## blackbox_exporter
##

  iptables_rule_drop_not_user "Drop unauthorized users to BlackboxExporter" do
    users ["prometheus"]
    port node[:blackbox_exporter][:port]
  end

  blackbox_exporter_instance = "#{node["fqdn"]}:#{node[:blackbox_exporter][:port]}"

  prometheus_scrape_targets "blackbox_exporter" do
    targets [
      {
        hosts: ["localhost:#{node[:blackbox_exporter][:port]}"],
        labels: {
          instance: blackbox_exporter_instance,
          job: "blackbox_exporter",
        },
      },
    ]
  end

  prometheus_rules "blackbox_exporter" do
    alerting_rules [
      {
        alert: "Blackbox Exporter Down",
        expr: <<~EOF,
          group(
            up{
              instance="#{blackbox_exporter_instance}",
              job="blackbox_exporter",
            } < 1
          )
        EOF
      },
    ]
  end

##
## alertmanager
##

  iptables_rule_drop_not_user "Drop unauthorized users to alertmanager" do
    users ["prometheus"]
    port node[:alertmanager][:cluster_port]
  end

  iptables_rule_drop_not_user "Drop unauthorized users to alertmanager" do
    users ["www-data", "prometheus", "grafana"]
    port node[:alertmanager][:web_port]
  end

  alertmanager_instance = "#{node["fqdn"]}:#{node[:alertmanager][:web_port]}"

  prometheus_scrape_targets "alertmanager" do
    targets [
      {
        hosts: ["localhost:#{node[:alertmanager][:web_port]}"],
        labels: {
          instance: alertmanager_instance,
          job: "alertmanager",
        },
      },
    ]
  end

  prometheus_rules "alertmanager" do
    alerting_rules [
      {
        alert: "AlertManager Down",
        expr: <<~EOF,
          group(
            up{
              instance="#{alertmanager_instance}",
              job="alertmanager",
            } < 1
          )
        EOF
      },
      {
        alert: "AlertManager Alerts Invalid",
        expr: <<~EOF,
          group by (version) (
            rate(
              alertmanager_alerts_invalid_total{
                instance="#{alertmanager_instance}",
                job="alertmanager",
              }[5m]
            ) > 0
          )
        EOF
      },
      {
        alert: "AlertManager Notification Requests Failed",
        expr: <<~EOF,
          group by (integration) (
            rate(
              alertmanager_notification_requests_failed_total{
                instance="#{alertmanager_instance}",
                job="alertmanager",
              }[5m]
            ) > 0
          )
        EOF
      },
      {
        alert: "AlertManager Notifications Failed",
        expr: <<~EOF,
          group by (integration) (
            rate(
              alertmanager_notifications_failed_total{
                instance="#{alertmanager_instance}",
                job="alertmanager",
              }[5m]
            ) > 0
          )
        EOF
      },
      {
        alert: "AlertManager Silences Query Errors",
        expr: <<~EOF,
          group(
            rate(
              alertmanager_silences_query_errors_total{
                instance="#{alertmanager_instance}",
                job="alertmanager",
              }[5m]
            ) > 0
          )
        EOF
      },
    ]
  end

##
## grafana
##

  iptables_rule_drop_not_user "Drop unauthorized users to Grafana" do
    users ["www-data", "prometheus"]
    port node[:grafana][:port]
  end

  grafana_url = "http://#{node[:grafana][:domain]}/"

  prometheus_scrape_targets_blackbox_http_401 "grafana" do
    targets [{hosts: [grafana_url]}]
  end

  grafana_instance = "#{node["fqdn"]}:#{node[:grafana][:port]}"

  prometheus_scrape_targets "grafana" do
    targets [
      {
        hosts: ["localhost:#{node[:grafana][:port]}"],
        labels: {
          instance: grafana_instance,
          job: "grafana",
        },
      },
    ]
  end

  prometheus_rules "grafana" do
    alerting_rules [
      {
        alert: "Grafana URL Down",
        expr: <<~EOF,
          group by (instance) (
            up{
              instance="#{grafana_url}",
              job="blackbox_http_401",
            } < 1
          )
        EOF
      },
      {
        alert: "Grafana Metrics Down",
        expr: <<~EOF,
          group(
            up{
              instance="#{grafana_instance}",
              job="grafana",
            } < 1
          )
        EOF
      },
    ]
  end

##
## prometheus
##

  iptables_rule_drop_not_user "Drop unauthorized users to Prometheus" do
    users ["www-data", "prometheus", "grafana"]
    port node[:prometheus][:port]
  end

  prometheus_blackbox_http_401_instance = "http://#{node[:prometheus][:domain]}/"

  prometheus_scrape_targets_blackbox_http_401 "prometheus" do
    targets [{hosts: [prometheus_blackbox_http_401_instance]}]
  end

  prometheus_instance = "#{node["fqdn"]}:#{node[:prometheus][:port]}"

  prometheus_scrape_targets "prometheus" do
    targets [
      {
        hosts: ["localhost:#{node[:prometheus][:port]}"],
        labels: {
          instance: prometheus_instance,
          job: "prometheus",
        },
      },
    ]
  end

  prometheus_rules "prometheus" do
    alerting_rules [
      {
        alert: "Prometheus Down",
        expr: <<~EOF,
          group by (instance) (
            up{
              instance="#{prometheus_blackbox_http_401_instance}",
              job="blackbox_http_401",
            } < 1
          )
        EOF
      },
      {
        alert: "Prometheus Scraping Down",
        expr: <<~EOF,
          group by (instance) (
            up{
              instance="#{prometheus_instance}",
              job="prometheus",
            } < 1
          )
        EOF
      },
      {
        alert: "Prometheus Notifications Dropped",
        expr: <<~EOF
          group(
            rate(
              prometheus_notifications_dropped_total{
                instance="#{prometheus_instance}",
                job="prometheus",
              }[5m]
            ) > 0
          )
        EOF
      },
      {
        alert: "Prometheus Notifications Errors",
        expr: <<~EOF
          group by (alertmanager) (
            rate(
              prometheus_notifications_errors_total{
                instance="#{prometheus_instance}",
                job="prometheus",
              }[5m]
            ) > 0
          )
        EOF
      },
      {
        alert: "Prometheus Sd Failed Configs",
        expr: <<~EOF
          group by (name) (
            prometheus_sd_failed_configs{
              instance="#{prometheus_instance}",
              job="prometheus",
            } > 0
          )
        EOF
      },
      {
        alert: "Prometheus Sd File Read Errors",
        expr: <<~EOF
          group(
            rate(
              prometheus_sd_file_read_errors_total{
                instance="#{prometheus_instance}",
                job="prometheus",
              }[5m]
            ) > 0
          )
        EOF
      },
      {
        alert: "Prometheus Rule Evaluation Failures",
        expr: <<~EOF,
          group by (rule_group) (
              prometheus_rule_evaluation_failures_total{
                instance="#{prometheus_instance}",
                job="prometheus",
              } > 0
          )
        EOF
      },
    ]
  end