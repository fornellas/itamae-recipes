node.validate! do
  {
    node_exporter: {
      version: string,
      arch: string,
      port: string,
    },
  }
end

version = node[:node_exporter][:version]
arch = node[:node_exporter][:arch]
port = node[:node_exporter][:port]

home_path = "/var/lib/node_exporter"
tar_gz_url = "https://github.com/prometheus/node_exporter/releases/download/v#{version}/node_exporter-#{version}.linux-#{arch}.tar.gz"

include_recipe "../iptables"

##
## Install
##

  # User / Group

  group "node_exporter"

  user "node_exporter" do
    gid "node_exporter"
    home home_path
    system_user true
    shell "/usr/sbin/nologin"
    create_home true
  end

  # Install

  execute "wget -O node_exporter.tar.gz #{tar_gz_url} && tar zxf node_exporter.tar.gz && chown root.root -R node_exporter-#{version}.linux-#{arch} && rm -rf /opt/node_exporter && mv node_exporter-#{version}.linux-#{arch} /opt/node_exporter && touch /opt/node_exporter/.#{version}.ok" do
    user "root"
    cwd "/tmp"
    not_if "test -f /opt/node_exporter/.#{version}.ok"
  end

  # Service

  template "/etc/systemd/system/node_exporter.service" do
    mode "644"
    owner "root"
    group "root"
    variables(install_path: "/opt/node_exporter")
    notifies :run, "execute[systemctl daemon-reload]"
  end

  execute "systemctl daemon-reload" do
    action :nothing
    user "root"
    notifies :restart, "service[node_exporter]"
  end

  service "node_exporter" do
    action [:enable, :start]
  end

  # iptables

  iptables_rule_drop_not_user "Drop not prometheus user to NodeExporter" do
    users ["prometheus"]
    port port
  end

##
## Monitoring
##

  node_exporter_instance = "#{node["fqdn"]}:#{port}"

  prometheus_scrape_targets "node_exporter" do
    targets [
      {
        hosts: ["127.0.0.1:#{port}"],
        labels: {
          instance: node_exporter_instance,
          exporter: "node_exporter",
        },
      },
    ]
  end

  prometheus_rules "node_exporter" do
    alerting_rules [
      {
        alert: "node_exporter Down",
        expr: <<~EOF,
          group(
            up{
              instance="#{node_exporter_instance}",
              exporter="node_exporter",
            } < 1
          )
        EOF
      },
    ]
  end