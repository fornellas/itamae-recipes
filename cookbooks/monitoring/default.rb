include_recipe "blackbox_exporter"
include_recipe "alertmanager"
include_recipe "grafana"
include_recipe "prometheus"
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

  # alertmanager

    prometheus_scrape_targets "alertmanager" do
      targets [
        {
          hosts: ["127.0.0.1:#{node[:alertmanager][:web_port]}"],
          labels: {
            instance: "#{node["fqdn"]}:#{node[:alertmanager][:web_port]}",
            exporter: "alertmanager",
          },
        },
      ]
    end

  # grafana

    prometheus_scrape_targets_blackbox_http_401 "grafana" do
      targets [
        {
          hosts: [
            "http://#{node[:grafana][:domain]}/"
          ]
        }
      ]
    end

    prometheus_rules "grafana" do
      alerting_rules [
        {
          alert: "GrafanaDown",
          expr: 'up{instance="http://'"#{node[:grafana][:domain]}"'/"} < 1',
        },
      ]
    end

  # prometheus

    prometheus_scrape_targets_blackbox_http_401 "prometheus" do
      targets [
        {
          hosts: [
            "http://#{node[:prometheus][:domain]}/"
          ]
        }
      ]
    end

    prometheus_scrape_targets "prometheus" do
      targets [
        {
          hosts: ["localhost:#{node[:prometheus][:port]}"],
          labels: {
            instance: "#{node["fqdn"]}:#{node[:prometheus][:port]}",
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

  # alertmanager

    prometheus_rules "alertmanager" do
      alerting_rules [
        {
          alert: "AlertManagerAlertsInvalid",
          expr: "rate(alertmanager_alerts_invalid_total{instance=\"#{node["fqdn"]}:#{node[:alertmanager][:web_port]}\"}[5m]) > 0",
        },
        {
          alert: "AlertManagerNotificationRequestsFailed",
          expr: "rate(alertmanager_notification_requests_failed_total{instance=\"#{node["fqdn"]}:#{node[:alertmanager][:web_port]}\"}[5m]) > 0",
        },
        {
          alert: "AlertManagerNotificationFailed",
          expr: "rate(alertmanager_notifications_failed_total{instance=\"#{node["fqdn"]}:#{node[:alertmanager][:web_port]}\"}[5m]) > 0",
        },
        {
          alert: "AlertManagerSilencesQueryErrors",
          expr: "rate(alertmanager_silences_query_errors_total{instance=\"#{node["fqdn"]}:#{node[:alertmanager][:web_port]}\"}[5m]) > 0",
        },
        {
          alert: "AlertManagerDown",
          expr: "up{instance=\"#{node["fqdn"]}:#{node[:alertmanager][:web_port]}\"} < 1",
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

  include_recipe "../iptables"

  # blackbox_exporter

    iptables_rule_drop_not_user "Drop not prometheus user to BlackboxExporter" do
      users ["prometheus"]
      port node[:blackbox_exporter][:port]
    end

  # alertmanager

    iptables_rule_drop_not_user "Drop not www-data|prometheus user to alertmanager" do
      users ["www-data", "prometheus"]
      port node[:alertmanager][:web_port]
    end

    iptables_rule_drop_not_user "Drop not prometheus user to alertmanager" do
      users ["prometheus"]
      port node[:alertmanager][:cluster_port]
    end

  # grafana

    iptables_rule_drop_not_user "Drop not www-data user to Grafana" do
      users ["www-data"]
      port node[:grafana][:port]
    end

  # prometheus

    iptables_rule_drop_not_user "Drop not www-data|prometheus|grafana user to Prometheus" do
      users [
        "www-data",
        "prometheus",
        # FIXME
        # "grafana"
      ]
      port node[:prometheus][:port]
    end