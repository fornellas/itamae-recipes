package "nginx"

remote_file "/etc/nginx/nginx.conf" do
  mode "644"
  owner "root"
  group "root"
  notifies :restart, "service[nginx]", :immediately
end

service "nginx" do
  action :enable
end
