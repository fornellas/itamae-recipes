##
## n2p
##

  n2p_ssh = "n2p.sigstop.co.uk:22"

  prometheus_scrape_targets_blackbox_ssh_banner "n2p" do
    targets [{ hosts: [n2p_ssh] }]
  end

  prometheus_rules "n2p" do
    alerting_rules [
      {
        alert: "n2p SSH Down",
        expr: <<~EOF,
          group by (instance) (
              probe_success{
                  job="blackbox_ssh_banner",
                  instance="#{n2p_ssh}",
              } < 1
          )
        EOF
        for: "2m",
      },
    ]
  end

##
## mmoj
##

  mmoj_ssh = "mmoj.sigstop.co.uk:22"

  prometheus_scrape_targets_blackbox_ssh_banner "mmoj" do
    targets [{ hosts: [mmoj_ssh] }]
  end

  prometheus_rules "mmoj" do
    alerting_rules [
      {
        alert: "mmoj SSH Down",
        expr: <<~EOF,
          group by (instance) (
              probe_success{
                  job="blackbox_ssh_banner",
                  instance="#{mmoj_ssh}",
              } < 1
          )
        EOF
        for: "1h",
      },
    ]
  end

##
## Internet
##

  prometheus_scrape_targets_blackbox_http_2xx "google_204" do
    targets [
      {
        hosts: ["https://www.google.com/generate_204"],
        labels: {
          internet: "true",
        },
      },
    ]
  end

  prometheus_scrape_targets_blackbox_http_2xx "gstatic_204" do
    targets [
      {
        hosts: ["http://connectivitycheck.gstatic.com/generate_204"],
        labels: {
          internet: "true",
        },
      },
    ]
  end

  prometheus_scrape_targets_blackbox_http_2xx "netflix" do
    targets [
      {
        hosts: ["https://www.netflix.com"],
        labels: {
          internet: "true",
        },
      },
    ]
  end

  prometheus_scrape_targets_blackbox_http_2xx "facebook" do
    targets [
      {
        hosts: ["https://www.facebook.com/"],
        labels: {
          internet: "true",
        },
      },
    ]
  end

  prometheus_rules "internet" do
    alerting_rules [
      {
        alert: "Internet Unreachable",
        expr: <<~EOF,
          sum(probe_success{
              internet="true",
          }) < 1
        EOF
      },
    ]
  end

##
## Brown
##

  brow_ip = "192.168.88.252"
  brown_instance_node_exporter_port = "9100"
  brown_instance_node_exporter = "brown.local:#{brown_instance_node_exporter_port}"
  brown_instance_wifi_exporter_port = "8034"
  brown_instance_wifi_exporter = "brown.local:#{brown_instance_wifi_exporter_port}"
  brown_instance_windows_exporter_port = "9182"
  brown_instance_windows_exporter = "brown.local:#{brown_instance_windows_exporter_port}"

  prometheus_scrape_targets "brown" do
    targets [
      {
        hosts: ["#{brow_ip}:#{brown_instance_node_exporter_port}"],
        labels: {
          instance: brown_instance_node_exporter,
          job: "node_exporter",
        },
      },
      {
        hosts: ["#{brow_ip}:#{brown_instance_wifi_exporter_port}"],
        labels: {
          instance: brown_instance_wifi_exporter,
          job: "wifi_exporter",
        },
      },
      {
        hosts: ["#{brow_ip}:#{brown_instance_windows_exporter_port}"],
        labels: {
          instance: brown_instance_windows_exporter,
          job: "windows_exporter",
        },
      },
    ]
  end

  channel_2_4GHz = 1
  channel_5GHz = 52

  prometheus_rules "brown" do
    alerting_rules [
      # node_exporter
      {
        alert: "Brown node_exporter Offline for Too long",
        expr: <<~EOF,
          group(
            avg_over_time(
              up{
                job="node_exporter",
                instance="#{brown_instance_node_exporter}"
              }[4d]
            ) == 0
          )
        EOF
      },
      # wifi_exporter
      {
        alert: "Brown wifi_exporter Offline for Too long",
        expr: <<~EOF,
          group(
            avg_over_time(
              up{
                job="node_exporter",
                instance="#{brown_instance_wifi_exporter}"
              }[4d]
            ) == 0
          )
        EOF
      },
      # {
      #   alert: "Competing 5GHz router found",
      #   expr: <<~EOF,
      #     group by (BSSID,SSID)(wifi_signal_db{
      #         job="wifi_exporter",
      #         instance=~"brown.local:8034",
      #         interface=~"wlp4s0",
      #         frequency_band=~"5GHz",
      #         channel=~"#{channel_5GHz}",
      #         BSSID!="90:5c:44:79:5e:4a"
      #     })
      #   EOF
      # },
      # {
      #   alert: "5GHz Wifi changed channel",
      #   expr: <<~EOF,
      #     sum(wifi_channel{
      #         job="wifi_exporter",
      #         instance=~"brown.local:8034",
      #         interface=~"wlp4s0",
      #         frequency_band=~"5GHz",
      #         BSSID="90:5c:44:79:5e:4a",
      #     } != #{channel_5GHz})
      #   EOF
      # },
      # {
      #   alert: "Competing 2.4GHz router found",
      #   expr: <<~EOF,
      #     group by (BSSID,SSID)(wifi_signal_db{
      #         job="wifi_exporter",
      #         instance=~"brown.local:8034",
      #         interface=~"wlp4s0",
      #         frequency_band=~"2.4GHz",
      #         channel=~"#{channel_2_4GHz}",
      #         BSSID!="90:5c:44:79:5e:5e", # VM2B47AA2-2.4GHz
      #         BSSID!="92:5c:14:79:5e:5e", # Horizon Wi-Free
      #     })
      #   EOF
      # },
      # {
      #   alert: "2.4GHz Wifi changed channel",
      #   expr: <<~EOF,
      #     sum(wifi_channel{
      #         job="wifi_exporter",
      #         instance=~"brown.local:8034",
      #         interface=~"wlp4s0",
      #         frequency_band=~"2.4GHz",
      #         BSSID="90:5c:44:79:5e:5e", # VM2B47AA2-2.4GHz
      #     } != #{channel_2_4GHz})
      #   EOF
      # },
      # windows_exporter
      {
        alert: "Brown windows_exporter Offline for Too long",
        expr: <<~EOF,
          group(
            avg_over_time(
              up{
                job="windows_exporter",
                instance="#{brown_instance_windows_exporter}"
              }[15d]
            ) == 0
          )
        EOF
      },
    ]
  end

##
## Printer
##

  printer_address_port = "192.168.88.242:80"

  prometheus_scrape_targets_brother_exporter "HL-L2350DW series" do
    instance "http://#{printer_address_port}/etc/mnt_info.csv"
   end