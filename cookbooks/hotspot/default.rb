require "shellwords"

include_recipe "../iptables"

node.validate! do
  {
    hotspot: {
      ifname: string,
      ssid: string,
      password: string,
      ipv4_address: string,
      allow_users: array_of(string),
    },
  }
end


ifname = node[:hotspot][:ifname]
ssid = node[:hotspot][:ssid]
password = node[:hotspot][:password]
ipv4_address = node[:hotspot][:ipv4_address]
allow_users = node[:hotspot][:allow_users] + ["root"]

con_name = "hotspot-#{ifname}"

##
## iptables
##

	# INPUT

		iptables "Accept INPUT from hotspot #{ifname} for domain" do
		  table "filter"
		  command :prepend
		  chain "INPUT"
		  rule_specification "--in-interface #{ifname} --protocol udp --match udp --destination-port domain --jump ACCEPT"
		end

		iptables "Accept INPUT from hotspot #{ifname} for bootps" do
		  table "filter"
		  command :prepend
		  chain "INPUT"
		  rule_specification "--in-interface #{ifname} --protocol udp --match udp --destination-port bootps --jump ACCEPT"
		end

		iptables "Accept INPUT from hotspot #{ifname} for mDNS" do
		  table "filter"
		  command :prepend
		  chain "INPUT"
		  rule_specification "--in-interface #{ifname} --source #{ipv4_address} --destination 224.0.0.0/24 --protocol udp --match udp --source-port mdns --destination-port mdns -j ACCEPT"
		end

		iptables "Accept INPUT from hotspot #{ifname} for IGMP" do
		  table "filter"
		  command :prepend
		  chain "INPUT"
		  rule_specification "--in-interface #{ifname} --source #{ipv4_address} --destination 224.0.0.0/24 --protocol igmp -j ACCEPT"
		end

		iptables "Accept INPUT from hotspot #{ifname} for UDP/1900" do
		  table "filter"
		  command :prepend
		  chain "INPUT"
		  rule_specification "--in-interface #{ifname} --source #{ipv4_address} --destination 239.0.0.0/8 --protocol udp --match udp --destination-port 1900 -j ACCEPT"
		end

		iptables "Log INPUT DROP from hotspot #{ifname}" do
		  table "filter"
		  command :append
		  chain "INPUT"
		  rule_specification "--in-interface #{ifname} --jump LOG --log-prefix 'INPUT from hotspot #{ifname}: ' --log-uid"
		end

		iptables "Drop INPUT from hotspot #{ifname} by default" do
		  table "filter"
		  command :append
		  chain "INPUT"
		  rule_specification "--in-interface #{ifname} --jump DROP"
		end

	# OUTPUT

		define :iptables_hotspot_allow_user do
		  user = params[:name]

			iptables "Accept OUTPUT to hotspot #{ifname} for #{user}" do
			  table "filter"
			  command :prepend
			  chain "OUTPUT"
			  rule_specification "--out-interface #{ifname} --match owner --uid-owner #{user} --jump ACCEPT"
			end
		end

		allow_users.each do |user|
			iptables_hotspot_allow_user user
		end

		iptables "Accept OUTPUT to #{ifname} for IGMP" do
		  table "filter"
		  command :prepend
		  chain "OUTPUT"
		  rule_specification "--out-interface #{ifname} --source #{ipv4_address} --destination 224.0.0.0/24 --protocol igmp -j ACCEPT"
		end

		iptables "Accept OUTPUT to hotspot #{ifname} for ESTABLISHED,RELATED" do
		  table "filter"
		  command :prepend
		  chain "OUTPUT"
		  rule_specification "--out-interface #{ifname} --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT"
		end

		iptables "Log OUTPUT DROP to hotspot #{ifname}" do
		  table "filter"
		  command :append
		  chain "OUTPUT"
		  rule_specification "--out-interface #{ifname} --jump LOG --log-prefix 'OUTPUT DROP to hotspot #{ifname}: ' --log-uid"
		end

		iptables "Drop OUTPUT to hotspot #{ifname} by default" do
		  table "filter"
		  command :append
		  chain "OUTPUT"
		  rule_specification "--out-interface #{ifname} --jump DROP"
		end

	# FORWARD

		iptables "Log FORWARD DROP to hotspot #{ifname}" do
		  table "filter"
		  command :append
		  chain "FORWARD"
		  rule_specification "--out-interface #{ifname} --jump LOG --log-prefix 'FORWARD DROP to hotspot #{ifname}: ' --log-uid"
		end

		iptables "Drop FORWARD to hotspot #{ifname}" do
		  table "filter"
		  command :append
		  chain "FORWARD"
		  rule_specification "--out-interface #{ifname} --jump DROP"
		end

##
## NetworkManager
##

execute "Add NetworkManager connection #{con_name}" do
  command "nmcli connection add type wifi ifname #{Shellwords.shellescape(ifname)} con-name #{Shellwords.shellescape(con_name)} ssid #{Shellwords.shellescape(ssid)}"
  not_if "PAGER=cat nmcli connection show #{Shellwords.shellescape(con_name)}"
end

define :nm_connection, connection: nil, value: nil do
	setting_property = params[:name]
 	con_name = params[:connection]
	value = params[:value]
	execute "Set NetworkManager connection #{con_name} #{setting_property}" do
		command "nmcli connection modify #{Shellwords.shellescape(con_name)} #{Shellwords.shellescape(setting_property)} #{Shellwords.shellescape(value)}"
		not_if "/bin/test \"$(PAGER=cat nmcli connection show #{Shellwords.shellescape(con_name)} --show-secrets | sed -rn 's/^#{Shellwords.shellescape(setting_property)}: +([^ ].*)$/\\1/p')\" == #{Shellwords.shellescape(value)}"
		notifies :run, "execute[Deactivate NetworkManager connection #{con_name}]"
	end
end

nm_connection "connection.autoconnect" do
	connection con_name
	value "yes"
end

nm_connection "802-11-wireless.mode" do
	connection con_name
	value "ap"
end

nm_connection "802-11-wireless-security.key-mgmt" do
	connection con_name
	value "wpa-psk"
end

nm_connection "802-11-wireless-security.group" do
	connection con_name
	value "ccmp"
end

nm_connection "802-11-wireless-security.pairwise" do
	connection con_name
	value "ccmp"
end

nm_connection "802-11-wireless-security.proto" do
	connection con_name
	value "rsn"
end

nm_connection "802-11-wireless-security.psk" do
	connection con_name
	value password
end

nm_connection "ipv4.method" do
	connection con_name
	value "shared"
end

nm_connection "ipv4.addresses" do
	connection con_name
	value ipv4_address
end

execute "Deactivate NetworkManager connection #{con_name}" do
  command "nmcli connection down #{Shellwords.shellescape(con_name)}"
  only_if "PAGER=cat nmcli connection show --active #{Shellwords.shellescape(con_name)} | grep -E '^connection\\.id: +#{Shellwords.shellescape(con_name)}$'"
  action :nothing
end

execute "Activate NetworkManager connection #{con_name}" do
  command "nmcli connection up #{Shellwords.shellescape(con_name)}"
  not_if "PAGER=cat nmcli connection show --active #{Shellwords.shellescape(con_name)} | grep -E '^connection\\.id: +#{Shellwords.shellescape(con_name)}$'"
end