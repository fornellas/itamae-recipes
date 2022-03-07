require "ipaddr"

package "aptitude"
package "avahi-daemon"
package "curl"
package "dc"
package "debhelper"
package "dmeventd"
package "ethtool"
package "gawk"
package "geoip-bin"
package "git"
package "hddtemp"
package "htop"
package "iftop"
package "iotop"
package "lvm2"
package "mc"
package "ngrep"
package "nload"
package "nmap"
package "ntpdate"
package "p7zip"
package "pm-utils"
package "pv"
package "pwgen"
package "reportbug"
package "rfkill"
package "screen"
package "ssh"
package "subversion"
package "sysstat"
package "traceroute"
package "ubuntu-core-libs"
package "ubuntu-core-libs-dev"
package "ubuntu-minimal"
package "ubuntu-standard"
package "unzip"
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
