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
collector_textfile_directory = node[:node_exporter][:collector_textfile_directory]

home_path = "/var/lib/node_exporter"
collector_textfile_directory = "#{home_path}/collector_textfile"
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

    directory collector_textfile_directory do
      owner "node_exporter"
      group "node_exporter"
      mode "770"
    end

    reboot_required_path = "/var/run/reboot-required"
    reboot_required_metric = "node_reboot_required"
    crontab = <<~EOF
      */1  *  *  *  * /usr/bin/test -f #{reboot_required_path} && echo #{reboot_required_metric} 1 > #{collector_textfile_directory}/reboot_required.prom || echo #{reboot_required_metric} 0 > #{collector_textfile_directory}/reboot_required.prom
    EOF
    escaped_crontab = Shellwords.shellescape(crontab)
    execute "crontab" do
      command "echo #{escaped_crontab} | crontab -u node_exporter -"
      only_if '[ "$(crontab -u node_exporter -l)" != '"#{escaped_crontab}"' ]'
    end

  # Service

    template "/etc/systemd/system/node_exporter.service" do
      mode "644"
      owner "root"
      group "root"
      variables(
        install_path: "/opt/node_exporter",
        collector_textfile_directory: collector_textfile_directory,
      )
      notifies :run, "execute[systemctl daemon-reload]"
      notifies :restart, "service[node_exporter]"
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
          job: "node_exporter",
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
              job="node_exporter",
            } < 1
          )
        EOF
      },
      {
        alert: "Failed systemd unit",
        expr: <<~EOF
          group by (instance,type,name) (
            node_systemd_unit_state{
              job="node_exporter",
              state="failed",
            } == 1
          )
        EOF
      },
      {
        alert: "Reboot Required",
        expr: <<~EOF
          group by (instance)(
            avg_over_time(
              #{reboot_required_metric}{
                instance="#{node_exporter_instance}",
                job="node_exporter",
              }[2d]
            ) == 0
          )
        EOF
      },
    ]
  end