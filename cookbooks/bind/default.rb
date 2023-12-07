package "bind9"

file "/etc/bind/named.conf.options" do
  owner "root"
  group "bind"
  mode "644"
  notifies :restart, "service[bind9]", :immediately
end

service "bind9" do
  action [:enable, :start]
end