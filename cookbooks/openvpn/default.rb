node.validate! do
  {
    openvpn: {
      domain: string,
      port: string,
      dns: string,
      server_network: string,
      server_netmask: string,
    },
    network: {
      local: string,
    },
  }
end

domain = node[:openvpn][:domain]
port = node[:openvpn][:port]
dns = node[:openvpn][:dns]
server_network = node[:openvpn][:server_network]
server_netmask = node[:openvpn][:server_netmask]

letsencrypt_ca = run_command("cat /usr/share/ca-certificates/mozilla/ISRG_Root_X1.crt").stdout.chomp

include_recipe "../nginx"
include_recipe "../letsencrypt"
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

    iptables "Drop traffic to local network" do
      table "filter"
      command :append
      chain "FORWARD"
      rule_specification "--source #{server_network}/#{server_netmask} --destination #{node[:network][:local]} -j DROP"
    end

    iptables "Masquerade outgoing traffic" do
      table "nat"
      command :append
      chain "POSTROUTING"
      rule_specification "--source #{server_network}/#{server_netmask} -j MASQUERADE"
    end

##
## DNS
##

  # Configuration

    directory "/etc/systemd/resolved.conf.d" do
      mode "755"
      owner "root"
      group "root"
    end

    template "/etc/systemd/resolved.conf.d/openvpn@#{domain}.conf" do
      source "templates//etc/systemd/resolved.conf.d/openvpn@domain.conf"
      mode "644"
      owner "root"
      group "root"
      variables(
        dns: dns,
      )
      notifies :restart, "service[systemd-resolved]"
    end

  # Service

    service "systemd-resolved" do
      action [:enable, :start]
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
        dns: dns,
        server_network: server_network,
        server_netmask: server_netmask,
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

    template "/etc/openvpn/#{domain}/#{domain}-windows.ovpn" do
      source "templates/etc/openvpn/domain/domain-windows.ovpn"
      mode "755"
      owner "root"
      group "root"
      variables(
        domain: domain,
        port: port,
        letsencrypt_ca: letsencrypt_ca,
      )
    end