package "nginx"
package "libnginx-mod-http-auth-pam"

execute "gpasswd -a www-data shadow" do
  not_if "getent group shadow | cut -d: -f4 | tr , \\\\n | grep -E '^www-data$'"
  notifies :restart, "service[nginx]", :immediately
end

remote_file "/etc/nginx/nginx.conf" do
  mode "644"
  owner "root"
  group "root"
  notifies :restart, "service[nginx]", :immediately
end

service "nginx" do
  action :enable
end
