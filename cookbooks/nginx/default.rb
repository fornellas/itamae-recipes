include_recipe "../group_add"

package "nginx"
package "libnginx-mod-http-auth-pam"

group_add "www-data" do
  groups ["shadow"]
  notifies :restart, "service[nginx]", :immediately
end

remote_file "/etc/nginx/nginx.conf" do
  mode "644"
  owner "root"
  group "root"
  notifies :restart, "service[nginx]", :immediately
end

service "nginx" do
  action [:enable, :start]
end
