node.validate! do
  {
    iptables_exporter: {
      port: string,
    },
  }
end

listen_port = node[:iptables_exporter][:port]

include_recipe "../golang"
include_recipe "../iptables"

##
## Install
##

  # User / Group

  group "iptables_exporter"

  user "iptables_exporter" do
    gid "iptables_exporter"
    system_user true
    shell "/usr/sbin/nologin"
    create_home true
  end

  # Install

  golang_install_bin "iptables_exporter" do
    package "github.com/retailnext/iptables_exporter"
  end

  # iptables

  iptables_rule_drop_not_user "Drop not prometheus user to iptables_exporter" do
    users ["prometheus"]
    port listen_port
  end

  # Service

  template "/etc/systemd/system/iptables_exporter.service" do
    mode "644"
    owner "root"
    group "root"
    variables(
      listen_address: "127.0.0.1:#{listen_port}",
    )
    notifies :run, "execute[systemctl daemon-reload]"
  end

  execute "systemctl daemon-reload" do
    action :nothing
    user "root"
    notifies :restart, "service[iptables_exporter]"
  end

  service "iptables_exporter" do
    action [:enable, :start]
  end

##
## Monitoring
##

  iptables_exporter_instance = "#{node["fqdn"]}:#{listen_port}"

  prometheus_scrape_targets "iptables_exporter" do
    targets [
      {
        hosts: ["127.0.0.1:#{listen_port}"],
        labels: {
          instance: iptables_exporter_instance,
          exporter: "iptables_exporter",
        },
      },
    ]
  end

  prometheus_rules "iptables_exporter" do
    alerting_rules [
      {
        alert: "IPTables Exporter Down",
        expr: <<~EOF,
          group(
            up{
              instance="#{iptables_exporter_instance}",
              exporter="iptables_exporter",
            } < 1
          )
        EOF
      },
      {
        alert: "IPTablesDrop",
        expr: <<~EOF,
          rate(
            iptables_rule_bytes_total{
              instance="#{iptables_exporter_instance}",
              exporter="iptables_exporter",
              rule=~".* -j DROP$",
            }[1m]
          ) > 0
        EOF
      },
    ]
  end