include_recipe "../iptables"

package "aptitude"

package "avahi-daemon"
iptables "Allow OUTPUT avahi traffic" do
  table "nat"
  command :prepend
  chain "OUTPUT"
  rule_specification "-m owner ! --uid-owner avahi -j ACCEPT"
end

package "bind9utils"
package "curl"
package "dc"
package "debhelper"
package "dmeventd"
package "ethtool"
package "ftp"
package "gawk"
package "geoip-bin"
package "git"
package "hdparm"
package "htop"
package "iftop"
package "info"
package "iotop"
package "iptables"
package "iw"
package "jq"
package "less"
package "lshw"
package "lsof"
package "lvm2"
package "mc"
package "ngrep"
package "nload"
package "nmap"
package "ntpdate"
package "p7zip"
package "parted"
package "pciutils"
package "pm-utils"
package "procps"
package "psmisc"
package "pv"
package "pwgen"
package "reportbug"
package "rfkill"
package "rsync"
package "screen"
package "speedtest-cli"
package "ssh"
package "strace"
package "stress"
package "subversion"
package "sysstat"
package "tcpdump"
package "time"
package "traceroute"
package "unzip"
package "usbutils"
package "wget"
package "whois"
package "zip"

##
## Vim
##

package "vim" do
  notifies :run, "execute[editor-alternative]", :immediately
end

execute "editor-alternative" do
  action :nothing
  command "/usr/bin/update-alternatives --set editor /usr/bin/vim.basic"
end

##
## locale
##

remote_file "/etc/locale.gen" do
  owner "root"
  group "root"
  mode "644"
  notifies :run, "execute[locale-gen]", :immediately
end

execute "locale-gen" do
  action :nothing
  command "/usr/sbin/locale-gen"
end

remote_file "/etc/default/locale" do
  owner "root"
  group "root"
  mode "644"
end
