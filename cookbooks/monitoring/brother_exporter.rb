node.validate! do
  {
    brother_exporter: {
      port: string,
    },
  }
end

listen_port = node[:brother_exporter][:port]
listen_address_port = "127.0.0.1:#{listen_port}"

include_recipe "../golang"
include_recipe "../iptables"

##
## Install
##

  # User / Group

  group "brother_exporter"

  user "brother_exporter" do
    gid "brother_exporter"
    system_user true
    shell "/usr/sbin/nologin"
  end

  # Install

  golang_install_bin "brother_exporter" do
    package "github.com/fornellas/brother_exporter@latest"
  end

  # Service

  template "/etc/systemd/system/brother_exporter.service" do
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
    notifies :restart, "service[brother_exporter]"
  end

  service "brother_exporter" do
    action [:enable, :start]
  end