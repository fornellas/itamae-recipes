node.validate! do
  {
    cherrymusic: {
      domain: string,
      port: string,
      media_path: string,
    },
  }
end

domain = node[:cherrymusic][:domain]
cherrymusic_port = node[:cherrymusic][:port]
media_path = node[:cherrymusic][:media_path]

var_path = "/var/lib/cherrymusic"
install_path = "#{var_path}/CherryMusic"
config_path = "#{var_path}/.config/cherrymusic/cherrymusic.conf"

include_recipe "../iptables"

##
## Deps
##

package "faad"
package "flac"
package "imagemagick"
package "ffmpeg"
package "lame"
package "mpg123"
package "opus-tools"
package "python3"
package "python3-unidecode"
package "vorbis-tools"

##
## User / Group
##

group "cherrymusic"

user "cherrymusic" do
  gid "cherrymusic"
  home var_path
  system_user true
  shell "/usr/sbin/nologin"
  create_home true
end

##
## CherryMusic
##

# iptables

iptables_rule_drop_not_user "Drop not www-data user to CherryMusic" do
  users ["www-data"]
  port cherrymusic_port
end

# Install

git install_path do
  user "cherrymusic"
  revision "origin/fornellas"
  repository "git://github.com/fornellas/cherrymusic.git"
end

execute "/usr/bin/yes | #{install_path}/cherrymusic" do
  user "cherrymusic"
  cwd install_path
  not_if "test -f #{config_path}"
end

directory media_path do
  mode "775"
  owner "cherrymusic"
  group "cherrymusic"
end

# Configuration

template config_path do
  owner "cherrymusic"
  group "cherrymusic"
  variables(
    port: cherrymusic_port,
    basedir: media_path,
  )
  notifies :restart, "service[cherrymusic]"
end

# Service

template "/etc/systemd/system/cherrymusic.service" do
  mode "644"
  owner "root"
  group "root"
  variables(install_path: install_path)
  notifies :run, "execute[systemctl daemon-reload]"
end

execute "systemctl daemon-reload" do
  action :nothing
  user "root"
  notifies :restart, "service[cherrymusic]"
end

service "cherrymusic" do
  action :enable
end

##
## Let's Encrypt
##

include_recipe "../letsencrypt"

letsencrypt domain

##
## Nginx
##

include_recipe "../nginx"

remote_file "/etc/pam.d/cherrymusic" do
  mode "644"
  owner "root"
  group "root"
end

template "/etc/nginx/sites-enabled/cherrymusic" do
  mode "644"
  owner "root"
  group "root"
  variables(
    domain: domain,
    cherrymusic_port: cherrymusic_port,
  )
  notifies :restart, "service[nginx]", :immediately
end

##
## Prometheus
##

prometheus_scrape_targets_blackbox_http_401 "cherrymusic" do
  targets [{ hosts: ["http://cherrymusic.sigstop.co.uk/"] }]
end
