blackbox_exporter_port = "9115"
version = "0.19.0"
arch = "armv7"
tar_gz_url = "https://github.com/prometheus/blackbox_exporter/releases/download/v#{version}/blackbox_exporter-#{version}.linux-#{arch}.tar.gz"

##
## blackbox_exporter
##

# User / Group

group 'blackbox_exporter'

user 'blackbox_exporter' do
	gid 'blackbox_exporter'
	system_user true
	shell '/usr/sbin/nologin'
	create_home false
end

# Install

execute "wget -O blackbox_exporter.tar.gz #{tar_gz_url} && tar zxf blackbox_exporter.tar.gz && chown root.root -R blackbox_exporter-#{version}.linux-#{arch} && rm -rf /opt/blackbox_exporter-tmp && mv blackbox_exporter-#{version}.linux-#{arch} /opt/blackbox_exporter-tmp && mv /opt/blackbox_exporter-tmp /opt/blackbox_exporter-#{version}" do
	user 'root'
	cwd "/tmp"
	not_if "test -d /opt/blackbox_exporter-#{version}"
end

# Configuration

directory "/etc/blackbox_exporter" do
    owner 'root'
    group 'root'
    mode '755'
end

remote_file "/etc/blackbox_exporter/blackbox.yml" do
	mode '644'
	owner 'root'
	group 'root'
	notifies :restart, 'service[blackbox_exporter]'
end

# Service

template "/etc/systemd/system/blackbox_exporter.service" do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		install_path: "/opt/blackbox_exporter-#{version}",
		config_file: "/etc/blackbox_exporter/blackbox.yml",
	)
	notifies :run, 'execute[systemctl daemon-reload]'
end

execute "systemctl daemon-reload" do
	action :nothing
	user 'root'
	notifies :restart, 'service[blackbox_exporter]'
end

service "blackbox_exporter" do
	action :enable
end