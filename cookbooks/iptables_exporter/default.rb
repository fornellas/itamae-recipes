listen_port = "9455"

include_recipe "../golang"
include_recipe "../iptables"

##
## iptables_exporter
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
  action :enable
end

# Prometheus

prometheus_file_sd "iptables_exporter" do
  targets [
    {
      hosts: ["127.0.0.1:#{listen_port}"],
      labels: {
        instance: "odroid.local:#{listen_port}",
        job: "iptables_exporter",
      },
    },
  ]
end
