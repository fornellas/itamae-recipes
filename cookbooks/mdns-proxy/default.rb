node.validate! do
  {
    mdns_proxy: {
      domain: string,
      interface: string,
      port: string,
      service: string,
      version: string,
    },
  }
end


domain = node[:mdns_proxy][:domain]
interface = node[:mdns_proxy][:interface]
port = node[:mdns_proxy][:port]
listen_address_port = "127.0.0.1:#{port}"
service = node[:mdns_proxy][:service]
version = node[:mdns_proxy][:version]

include_recipe "../golang"
include_recipe "../iptables"
include_recipe "../letsencrypt"
include_recipe "../nginx"

##
## mDNS Proxy
##

  # User / Group

    group "mdns-proxy"

    user "mdns-proxy" do
      gid "mdns-proxy"
      system_user true
      shell "/usr/sbin/nologin"
    end

  # iptables

    iptables_rule_drop_not_user "Drop not www-data user to mDNS Proxy" do
      users ["www-data"]
      port port
    end

    iptables "Allow OUTPUT mdns-proxy traffic to #{interface}" do
      table "filter"
      command :prepend
      chain "OUTPUT"
      rule_specification "--out-interface #{interface} -m owner --uid-owner mdns-proxy -j ACCEPT"
    end

    iptables "Allow ESTABLISHED,RELATED INPUT from #{interface} to mdns-proxy" do
      table "filter"
      command :prepend
      chain "INPUT"
      rule_specification "--in-interface #{interface} --match conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
      notifies :run, "execute[netfilter-persistent save]", :immediately
    end

  # Install

    golang_install_bin "mdns-proxy" do
      package "github.com/fornellas/mdns-proxy@#{version}"
    end

  # Service

    template "/etc/systemd/system/mdns-proxy.service" do
      mode "644"
      owner "root"
      group "root"
      variables(
        address: listen_address_port,
        base_domain: domain,
        interface: interface,
        service: service,
      )
      notifies :run, "execute[systemctl daemon-reload]"
      notifies :restart, "service[mdns-proxy]"
    end

    execute "systemctl daemon-reload" do
      action :nothing
      user "root"
      notifies :restart, "service[mdns-proxy]"
    end

    service "mdns-proxy" do
      action [:enable, :start]
    end

##
## Nginx
##

  # Certificate

    letsencrypt "#{domain},*.#{domain}"

  # Auth

    remote_file "/etc/pam.d/mdns-proxy" do
      mode "644"
      owner "root"
      group "root"
    end

  # Configuration

    template "/etc/nginx/sites-enabled/mdns-proxy" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        mdns_proxy_port: port,
      )
      notifies :restart, "service[nginx]", :immediately
    end