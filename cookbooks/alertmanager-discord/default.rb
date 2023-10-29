listen_port = "9096"

include_recipe "../golang"
include_recipe "../iptables"

##
## alertmanager-discord
##

# User / Group

group "alertmanager-discord"

user "alertmanager-discord" do
  gid "alertmanager-discord"
  system_user true
  shell "/usr/sbin/nologin"
  create_home true
end

# Install

golang_install_bin "alertmanager-discord" do
  package "github.com/benjojo/alertmanager-discord@latest"
end

# iptables

iptables_rule_drop_not_user "Drop not alertmanager user to alertmanager-discord" do
  users ["alertmanager"]
  port listen_port
end

# Service

node.validate! do
  {
    alertmanager_discord: {
      webhook: string,
    },
  }
end

discord_webhook = node[:alertmanager_discord][:webhook]

template "/etc/systemd/system/alertmanager-discord.service" do
  mode "644"
  owner "root"
  group "root"
  variables(
    discord_webhook: discord_webhook,
    gohome: "/opt/go",
    listen_address: "127.0.0.1:#{listen_port}",
  )
  notifies :run, "execute[systemctl daemon-reload]"
end

execute "systemctl daemon-reload" do
  action :nothing
  user "root"
  notifies :restart, "service[alertmanager-discord]"
end

service "alertmanager-discord" do
  action [:enable, :start]
end
