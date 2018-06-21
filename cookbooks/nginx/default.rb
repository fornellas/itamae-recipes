package 'nginx'

remote_file "/etc/nginx/conf.d/server_names_hash_bucket_size.conf" do
	mode '644'
	owner 'root'
	group 'root'
	notifies :restart, 'service[nginx]', :immediately
end

service "nginx" do
	action :enable
end