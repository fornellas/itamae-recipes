node.validate! do
  {
    homeassistant: {
      domain: string,
      port: string,
      version: string,
      tz: string,
      long_lived_access_token: string,
    },
  }
end

domain = node[:homeassistant][:domain]
port = node[:homeassistant][:port]
version = node[:homeassistant][:version]
tz = node[:homeassistant][:tz]
long_lived_access_token = node[:homeassistant][:long_lived_access_token]

home_path = "/var/lib/homeassistant"
config_path = "#{home_path}/config"

include_recipe "../backblaze"
include_recipe "../iptables"
include_recipe "../group_add"
include_recipe "../letsencrypt"
include_recipe "../nginx"

##
## Home Assistant
##

  # Docker

    package "docker.io"

  # User & Group

    group "homeassistant"

    user "homeassistant" do
      gid "homeassistant"
      home home_path
      system_user true
      shell "/usr/sbin/nologin"
      create_home true
    end

    group_add "homeassistant" do
      groups ["docker"]
    end

  # iptables

    iptables_rule_drop_not_user "Drop not www-data user to Home Assistant" do
      users ["www-data"]
      port port
    end

  # Service

    template "/etc/systemd/system/homeassistant.service" do
      mode "644"
      owner "root"
      group "root"
      variables(
        config_path: config_path,
        tz: tz,
        version: version,
      )
      notifies :run, "execute[systemctl daemon-reload]"
      notifies :restart, "service[homeassistant]"
    end

    execute "systemctl daemon-reload" do
      action :nothing
      user "root"
      notifies :restart, "service[homeassistant]"
    end

    service "homeassistant" do
      action [:enable, :start]
    end

  # Prometheus

    prometheus_scrape_config "homeassistant" do
      scrape_configs [
        {
          job_name: "homeassistant",
          metrics_path: "/api/prometheus",
          authorization: {
            credentials: long_lived_access_token,
          },
          scheme: "https",
          static_configs: [
            {
              targets: [
                domain,
              ],
            },
          ],
        }
      ]
    end

  # Backup

    # FIXME should use HA's API to trigger backup first
    backblaze "#{node["fqdn"].tr(".", "-")}-homeassistant" do
      backup_paths [config_path]
      user "root"
      group "root"
      bin_path home_path
    end

##
## Nginx
##

  # Certificate

    letsencrypt domain

  # Configuration

    remote_file "/etc/pam.d/homeassistant" do
      mode "644"
      owner "root"
      group "root"
    end

    template "/etc/nginx/sites-enabled/homeassistant" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        port: port,
      )
      notifies :restart, "service[nginx]", :immediately
    end

##
## Monitoring
##

  homeassistant_instance = "https://#{domain}/"

  prometheus_scrape_targets_blackbox_http_2xx "homeassistant" do
    targets [{ hosts: [homeassistant_instance] }]
  end

  prometheus_rules "homeassistant" do
    alerting_rules [
      {
        alert: "homeassistant Down",
        expr: <<~EOF,
          group(
            probe_success{
              instance="#{homeassistant_instance}",
              job="blackbox_http_2xx",
            } < 1
          )
        EOF
        for: "2m",
      },
    ]
  end