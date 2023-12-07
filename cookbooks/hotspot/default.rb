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




# nmcli con modify Hostspot wifi-sec.key-mgmt wpa-psk
# nmcli con modify Hostspot wifi-sec.psk "veryveryhardpassword1234"
# nmcli con up Hostspot


# nmcli connection modify wifi_access_point ipv4.addresses 192.168.1.1/24


#nmcli device wifi hotspot ifname wlan0 con-name wifi_access_point ssid odroid password 'D0jbh{#jZ&{EZ~e'

# nmcli connection add type wifi ifname wlan0 con-name hotspot autoconnect yes ssid HA
# nmcli connection modify hotspot ipv4.method shared ipv4.addresses 192.168.16.1/24
# nmcli connection modify hotspot ipv4.dns 192.168.16.1


# nmcli device wifi hotspot con-name hotspot ssid HA password 'wmt%rI3p8*D(`qX'
# nmcli connection modify hotspot ipv4.method shared ipv4.addresses 192.168.16.1/24


# remote_file "/etc/NetworkManager/system-connections/wifi_access_point.nmconnection" do
#   owner "root"
#   group "root"
#   mode "644"
#   notifies :restart, "service[NetworkManager]"
# end

# service "NetworkManager" do
#   action [:enable, :start]
# end

# apt install dkms
# #apt install iw
# git clone https://github.com/Mange/rtl8192eu-linux-driver
# vim Makefile
# 	< CONFIG_PLATFORM_I386_PC = y
# 	> CONFIG_PLATFORM_I386_PC = n
# 	...
# 	< CONFIG_PLATFORM_ARM_AARCH64 = n
# 	> CONFIG_PLATFORM_ARM_AARCH64 = y
# dkms add .
# dkms install rtl8192eu/1.0
# echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf
# echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf
# sudo update-grub; sudo update-initramfs -u
# systemctl reboot -i
# #apt install hostapd
# modprobe 8192eu
# nmcli device wifi hotspot ifname wlan0 con-name odroid ssid odroid password 'D0jbh{#jZ&{EZ~e'
# # connection created at
# # /etc/NetworkManager/system-connections
# # which has the range, may be able to create the file manually




