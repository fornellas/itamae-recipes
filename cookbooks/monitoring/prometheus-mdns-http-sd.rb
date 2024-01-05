node.validate! do
  {
    prometheus_mdns_http_sd: {
      port: string,
    },
  }
end

listen_port = node[:prometheus_mdns_http_sd][:port]
listen_address_port = "127.0.0.1:#{listen_port}"

include_recipe "../golang"
include_recipe "../iptables"
include_recipe "../hotspot"

##
## Install
##

  # User / Group

  group "prometheus-mdns-http-sd"

  user "prometheus-mdns-http-sd" do
    gid "prometheus-mdns-http-sd"
    system_user true
    shell "/usr/sbin/nologin"
  end

  # Install

  golang_install_bin "prometheus-mdns-http-sd" do
    package "github.com/fornellas/prometheus-mdns-http-sd@v0.0.5"
  end

  iptables_hotspot_allow_user "prometheus-mdns-http-sd" do
  end

  # Service

  template "/etc/systemd/system/prometheus-mdns-http-sd.service" do
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
    notifies :restart, "service[prometheus-mdns-http-sd]"
  end

  service "prometheus-mdns-http-sd" do
    action [:enable, :start]
  end