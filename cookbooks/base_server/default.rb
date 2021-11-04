# Base Server

package 'ifupdown'
package 'openntpd'
package 'prometheus-node-exporter'

include_recipe "../../cookbooks/bind"
include_recipe "../../cookbooks/postfix"

##
## OpenSSH Server
##

local_networks = run_command(
    "/sbin/ip addr | /bin/grep -E ' inet ' | /usr/bin/gawk '{print $2}'",
).stdout.split("\n").map do |line|
    address, mask = line.split("/")
    mask = "32" if not mask
    network_address = IPAddr.new(line).to_s
    "#{network_address}/#{mask}"
end

package 'libpam-google-authenticator'

template "/etc/security/access-no-google-authenticator.conf" do
    owner 'root'
    group 'root'
    mode '644'
    variables(no_google_authenticator_networks: local_networks)
end

remote_file "/etc/pam.d/common-auth-google-authenticator" do
    owner 'root'
    group 'root'
    mode '644'
end

package 'openssh-server'

file "/etc/pam.d/sshd" do
    action :edit
    block do |content|
        after = "\n@include common-auth\n"
        add = <<~EOF
            # Google Authenticator
            @include common-auth-google-authenticator
        EOF
        unless content.include?(add)
            s = content.split(after)
            raise "'#{after}' not found exactly one time!" unless s.length == 2
            content.replace("#{s.first}#{after}\n#{add}#{s.last}")
        end
    end
end

template "/etc/ssh/sshd_config" do
    owner 'root'
    group 'root'
    mode '644'
    variables(trusted_network_addresses: local_networks)
    notifies :restart, 'service[sshd]', :immediately
end
service 'sshd'

##
## Unattended Upgrades
##

package 'apt-listchanges'
package 'unattended-upgrades'

remote_file '/etc/apt/apt.conf.d/50unattended-upgrades' do
    owner 'root'
    group 'root'
    mode '644'
    notifies :restart, 'service[unattended-upgrades]', :immediately
end

service 'unattended-upgrades' do
    action :enable
end