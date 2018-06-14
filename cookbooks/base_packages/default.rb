package 'dc'
package 'debhelper'
package 'dmeventd'
package 'ethtool'
package 'geoip-bin'
package 'git'
package 'hddtemp'
package 'htop'
package 'iftop'
package 'ifupdown'
package 'iotop'
package 'lvm2'
package 'mc'
package 'ngrep'
package 'nload'
package 'nmap'
package 'ntpdate'
package 'openntpd'

package 'openssh-server'
file "/etc/ssh/sshd_config" do
  action :edit
  block do |content|
    content.gsub!("PermitRootLogin yes", "PermitRootLogin no")
  end
  notifies :restart, 'service[sshd]', :immediately
end
service 'sshd'

package 'p7zip'
package 'pm-utils'
package 'pv'
package 'pwgen'
package 'reportbug'
package 'rfkill'
package 'screen'
package 'ssh'
package 'subversion'
package 'sysstat'
package 'traceroute'
package 'ubuntu-core-libs'
package 'ubuntu-core-libs-dev'
package 'ubuntu-minimal'
package 'ubuntu-standard'
package 'unattended-upgrades'
package 'unzip'

package 'vim' do
	notifies :run, 'execute[editor-alternative]', :immediately
end
execute 'editor-alternative' do
	action :nothing
	command '/usr/bin/update-alternatives --set editor /usr/bin/vim.basic'
end

package 'wget'
package 'zip'

remote_file '/etc/locale.gen' do
	owner 'root'
	group 'root'
	mode '644'
	notifies :run, 'execute[locale-gen]', :immediately
end

execute 'locale-gen' do
	action :nothing
	command '/usr/sbin/locale-gen'
end

remote_file '/etc/default/locale'  do
	owner 'root'
	group 'root'
	mode '644'
end