node.validate! do
  {
    octoprint: {
      domain: string,
      port: string,
      webcam_url: string,
      webcam_stream_url: string,
      webcam_still_url: string,
    },
  }
end

domain = node[:octoprint][:domain]
port = node[:octoprint][:port]

var_path = "/var/lib/octoprint"
octoprint_bin = "#{var_path}/.local/bin/octoprint"
basedir_path = "#{var_path}/.octoprint"
config_path = "#{basedir_path}/config.yaml"
restart_service_cmd = "/bin/systemctl restart octoprint.service"
local_networks = run_command(
  "/sbin/ip addr | /bin/grep -E ' inet ' | /usr/bin/gawk '{print $2}'",
).stdout.split("\n").map do |line|
  address, mask = line.split("/")
  mask = "32" unless mask
  network_address = IPAddr.new(line).to_s
  "#{network_address}/#{mask}"
end

include_recipe "../group_add"
include_recipe "../backblaze"
include_recipe "../iptables"
include_recipe "../letsencrypt"
include_recipe "../nginx"

##
## Dependencies
##

  package "python3-pip"
  package "python3-dev"
  package "python3-virtualenv"
  package "libyaml-dev"
  package "build-essential"

##
## Install
##

  # User & Group

    group "octoprint"

    user "octoprint" do
      gid "octoprint"
      home var_path
      system_user true
      shell "/usr/sbin/nologin"
      create_home true
    end

    group_add "octoprint" do
      groups ["tty", "dialout"]
    end

  # Install

    execute "pip install octoprint" do
      user "octoprint"
      not_if "test -e #{octoprint_bin}"
    end

  # sudo

    file "/etc/sudoers.d/octoprint" do
      mode "644"
      owner "root"
      group "root"
      content "octoprint ALL=(ALL:ALL) NOPASSWD: #{restart_service_cmd}\n"
    end

  # Default Config

    execute "mkdir #{basedir_path}" do
      user "octoprint"
      not_if "test -d #{basedir_path}"
    end

    template config_path do
      mode "644"
      owner "octoprint"
      group "octoprint"
      not_if "test -e #{config_path}"
      variables(
        serverRestartCommand: "/usr/bin/sudo #{restart_service_cmd}",
      )
    end

  # iptables

    iptables_rule_drop_not_user "Drop not www-data user to OctoPrint" do
      users ["www-data", "octoprint"]
      port port
    end

  # Service

    template "/etc/systemd/system/octoprint.service" do
      mode "644"
      owner "root"
      group "root"
      variables(
        octoprint_bin: octoprint_bin,
        config_path: config_path,
        basedir_path: basedir_path,
        port: port,
      )
      notifies :run, "execute[systemctl daemon-reload]"
    end

    execute "systemctl daemon-reload" do
      action :nothing
      user "root"
      notifies :restart, "service[octoprint]"
    end

    service "octoprint" do
      action [:enable, :start]
    end

  # Backup

    backblaze "#{node["fqdn"].tr(".", "-")}-octoprint" do
      backup_paths [var_path]
      user "octoprint"
      group "octoprint"
      cron_hour 3
      cron_minute 10
    end

##
## Nginx
##

  # Mods

    package "libnginx-mod-http-headers-more-filter"

  # Certificate

    letsencrypt domain

  # Auth  

    remote_file "/etc/pam.d/octoprint" do
      mode "644"
      owner "root"
      group "root"
    end

  # Configuration

    template "/etc/nginx/sites-enabled/octoprint" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        port: port,
        webcam_url: node[:octoprint][:webcam_url],
        webcam_stream_url: node[:octoprint][:webcam_stream_url],
        webcam_still_url: node[:octoprint][:webcam_still_url],
        api_allow_networks: local_networks,
      )
      notifies :restart, "service[nginx]", :immediately
    end

##
## Scrape Targets
##

  prometheus_scrape_targets_blackbox_http_401 "octoprint" do
    targets [{ hosts: ["http://#{domain}/"] }]
  end

##
## Rules & Alerts
##

  prometheus_rules "octoprint" do
    alerting_rules [
      {
        alert: "OctoPrintDown",
        expr: 'up{instance="'"http://#{domain}/"'"} < 1',
      },
    ]
  end