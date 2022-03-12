node.validate! do
  {
    openvpn: {
      domain: string,
      port: string,
      dns: string,
      server_network: string,
      server_netmask: string,
    },
  }
end

domain = node[:openvpn][:domain]
port = node[:openvpn][:port]

letsencrypt_ca = run_command("cat /usr/share/ca-certificates/mozilla/ISRG_Root_X1.crt").stdout.chomp
default_gateway_dev = run_command(
  "/sbin/ip route | awk '/^default via/{print $5}'",
).stdout.chomp

default_gateway_dev_addr = run_command(
  "/sbin/ip route list table 0 | awk '/^local /{if($4==\"#{default_gateway_dev}\"){print $2;exit}}'",
).stdout.chomp

include_recipe "../nginx"
include_recipe "../letsencrypt"
include_recipe "../bind"
include_recipe "../iptables"

##
## PAM
##

  # Auth

    package "libpam-google-authenticator"

    remote_file "/etc/pam.d/openvpn" do
      mode "644"
      owner "root"
      group "root"
    end

##
## Network
##

  # sysctl

    file "/etc/sysctl.d/99-ipv4_forwarding.conf" do
      mode "644"
      owner "root"
      group "root"
      content "net.ipv4.conf.all.forwarding=1"
      notifies :restart, "service[procps]"
    end

    service "procps" do
      action [:enable, :start]
    end

  # iptables

    iptables_rule "Masquerade outgoing traffic" do
      table "nat"
      rule "POSTROUTING -o #{default_gateway_dev} ! -s #{default_gateway_dev_addr} -j MASQUERADE"
    end

##
## Let's Encrypt
##

  # Certificate

    letsencrypt domain
    
##
## OpenVPN
##
  
  # Install

    package "openvpn"

  # Configuration

    directory "/etc/openvpn/#{domain}/" do
      mode "755"
      owner "root"
      group "root"
    end

    template "/etc/openvpn/#{domain}.conf" do
      source "templates/etc/openvpn/domain.conf"
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        port: port,
        server_network: node[:openvpn][:server_network],
        server_netmask: node[:openvpn][:server_netmask],
      )
      notifies :restart, "service[openvpn@#{domain}]"
    end

  # Service

    directory "/etc/systemd/system/openvpn@#{domain}.service.d" do
      mode "755"
      owner "root"
      group "root"
    end

    file "/etc/systemd/system/openvpn@#{domain}.service.d/override.conf" do
      mode "644"
      owner "root"
      group "root"
      content <<~EOF
                [Service]
                # Required by pam_google_authenticator.so
                ProtectHome=false
                # Required by pam_unix.so
                CapabilityBoundingSet=CAP_AUDIT_WRITE
              EOF
      notifies :run, "execute[systemctl daemon-reload]"
    end

    execute "systemctl daemon-reload" do
      action :nothing
      user "root"
      notifies :restart, "service[openvpn@#{domain}]"
    end

    service "openvpn@#{domain}" do
      action [:enable, :start]
    end


##
## Nginx
##

  # Nginx Configuration

    template "/etc/nginx/sites-enabled/openvpn" do
      mode "644"
      owner "root"
      group "root"
      variables(domain: domain)
      notifies :restart, "service[nginx]", :immediately
    end

  # OpenVPN Client Configuration

    template "/etc/openvpn/#{domain}/#{domain}.ovpn" do
      source "templates/etc/openvpn/domain/domain.ovpn"
      mode "755"
      owner "root"
      group "root"
      variables(
        domain: domain,
        port: port,
        letsencrypt_ca: letsencrypt_ca,
      )
    end