package "dkms"

execute "Install rtl8852bu-dkms.deb" do
  command "wget -O /tmp/rtl8852bu-dkms.deb https://linux.brostrend.com/rtl8852bu-dkms.deb && dpkg -i /tmp/rtl8852bu-dkms.deb && rm -f /tmp/rtl8852bu-dkms.deb"
  not_if "dpkg -s grafana | grep -E '^Status: install ok installed$'"
end

execute "modprobe 8852bu" do
  command "modprobe 8852bu"
  not_if "lsmod | grep -E '^8852bu '"
end