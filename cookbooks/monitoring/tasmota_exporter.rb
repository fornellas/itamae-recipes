node.validate! do
  {
    tasmota_exporter: {
      port: string,
    },
  }
end

listen_port = node[:tasmota_exporter][:port]
listen_address_port = "127.0.0.1:#{listen_port}"

include_recipe "../golang"
include_recipe "../iptables"

##
## Install
##

  # User / Group

  group "tasmota_exporter"

  user "tasmota_exporter" do
    gid "tasmota_exporter"
    system_user true
    shell "/usr/sbin/nologin"
  end

  # Install

  golang_install_bin "tasmota_exporter" do
    package "github.com/fornellas/tasmota_exporter@v0.0.3"
  end

  # Service

  template "/etc/systemd/system/tasmota_exporter.service" do
    mode "644"
    owner "root"
    group "root"
    variables(
      listen_address: listen_address_port,
    )
    notifies :run, "execute[systemctl daemon-reload]"
  end

  execute "systemctl daemon-reload" do
    action :nothing
    user "root"
    notifies :restart, "service[tasmota_exporter]"
  end

  service "tasmota_exporter" do
    action [:enable, :start]
  end