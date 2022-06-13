include_recipe "../../cookbooks/base_system"
include_recipe "../../cookbooks/fornellas"
include_recipe "../../cookbooks/base_server"
include_recipe "../../cookbooks/no_auth_from_securetty"
include_recipe "../../cookbooks/monitoring"
backblaze "#{node["fqdn"].tr(".", "-")}-fornellas" do
  backup_paths ["/home/fornellas"]
  user "fornellas"
  group "fornellas"
end
include_recipe "../../cookbooks/tigervnc"
include_recipe "home"
include_recipe "../../cookbooks/node_exporter"
include_recipe "../../cookbooks/iptables_exporter"
include_recipe "../../cookbooks/cherrymusic"
include_recipe "../../cookbooks/octoprint"
include_recipe "../../cookbooks/openvpn"
include_recipe "../../cookbooks/nextcloud"
include_recipe "../../cookbooks/ttrss"