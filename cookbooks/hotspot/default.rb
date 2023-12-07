require "shellwords"

node.validate! do
  {
    hotspot: {
      ifname: string,
      ssid: string,
      password: string,
      ipv4_address: string,
    },
  }
end


ifname = node[:hotspot][:ifname]
ssid = node[:hotspot][:ssid]
password = node[:hotspot][:password]
ipv4_address = node[:hotspot][:ipv4_address]

con_name = "hotspot-#{ifname}"

# nmcli con add type wifi ifname wlan0 con-name Hostspot autoconnect yes ssid Hostspot
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

execute "Activate NetworkManager connection #{con_name}" do
  command "nmcli connection up #{Shellwords.shellescape(con_name)}"
  not_if "PAGER=cat nmcli connection show --active #{Shellwords.shellescape(con_name)} | grep -E '^connection\\.id: +#{Shellwords.shellescape(con_name)}$'"
end