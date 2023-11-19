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
        for: "2m",
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

  prometheus_scrape_targets_blackbox_http_2xx "virgin_router" do
    targets [
      {
        hosts: ["192.168.0.1:80"],
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
      {
        alert: "Virgin Router Unreachable",
        expr: <<~EOF,
          probe_success{
              instance="192.168.0.1:80"
          } != 1
        EOF
        for: "1m",
      },
    ]
  end

##
## Brown
##

  brow_ip = "192.168.0.221"
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
## Office Sensor
##

  office_sensor_instance_ip = "192.168.0.178:9090"
  office_sensor_instance = "office_sensors.local:9090"

  prometheus_scrape_targets "office_sensors" do
    targets [
      {
        hosts: [office_sensor_instance_ip],
        labels: {
          instance: office_sensor_instance,
          job: "sensor",
        },
      },
    ]
  end

  prometheus_rules "office_sensors" do
    alerting_rules [
      {
        alert: "Office Sensor Down",
        expr: <<~EOF,
          group(
              up{
                  instance="#{office_sensor_instance}",
              } < 1
          )
        EOF
        for: "5m",
      },
      {
        alert: "Low Office Temperature",
        expr: <<~EOF,
          group(
            temperature_celsius{
              instance="#{office_sensor_instance}",
            } < 20
          )
        EOF
      },
      {
        alert: "High Office Humidity",
        expr: <<~EOF,
          group(
            relative_humidity_ratio{
              instance="#{office_sensor_instance}",
            } > 0.80
          )
        EOF
      },
      {
        alert: "High Office CO₂ Concentration",
        expr: <<~EOF,
          group(
            co2_concentration_ppm{
              instance="#{office_sensor_instance}",
            } > 1600
          )
        EOF
      },
    ]
  end

##
## Living Room
##

  living_room_instance_ip = "192.168.0.164:9090"
  living_room_instance = "living_room_sensors.local:9090"

  prometheus_scrape_targets "living_room_sensors" do
    targets [
      {
        hosts: [living_room_instance_ip],
        labels: {
          instance: living_room_instance,
          job: "sensor",
        },
      },
    ]
  end

  prometheus_rules "living_room_sensors" do
    alerting_rules [
      {
        alert: "Living Room Sensor Down",
        expr: <<~EOF,
          group(
              up{
                  instance="#{living_room_instance}",
              } < 1
          )
        EOF
        for: "5m",
      },
      {
        alert: "Living Room Low Temperature",
        expr: <<~EOF,
          group(
            temperature_celsius{
              instance="#{living_room_instance}",
            } < 20
          )
        EOF
      },
      {
        alert: "High Living Room Humidity",
        expr: <<~EOF,
          group(
            relative_humidity_ratio{
              instance="#{living_room_instance}",
            } > 0.80
          )
        EOF
      },
    ]
  end

##
## Power Meter
##

  power_meter_instance_ip = "192.168.0.121:9090"
  power_meter_instance = "power_meter.local:9090"

  prometheus_scrape_targets "power_meter" do
    targets [
      {
        hosts: [power_meter_instance_ip],
        labels: {
          instance: power_meter_instance,
          job: "power_meter",
        },
      },
    ]
  end

  prometheus_rules "power_meter" do
    alerting_rules [
      {
        alert: "Power Meter Down",
        expr: <<~EOF,
          group(
              up{
                  instance="#{power_meter_instance}"
              } < 1
          )
        EOF
        for: "5m",
      },
      {
        alert: "Power Meter Stuck",
        expr: <<~EOF,
          changes(voltage_volts{
            instance="#{power_meter_instance}",
          }[10m]) == 0
        EOF
        for: "5m",
      },
      {
        alert: "High Power Usage (1h average)",
        expr: <<~EOF,
          group(
            avg_over_time(
              power_wats{
                instance="#{power_meter_instance}",
              }[1h]
            ) > 1900
          )
        EOF
      },
      {
        alert: "High Power Usage (1d average)",
        expr: <<~EOF,
          group(
            avg_over_time(
              power_wats{
                instance="#{power_meter_instance}",
              }[1d]
            ) > 450
          )
        EOF
      },
    ]
  end

##
## Printer
##

  printer_address_port = "192.168.0.100:80"

  prometheus_scrape_targets_brother_exporter "HL-L2350DW series" do
    instance "http://#{printer_address_port}/etc/mnt_info.csv"
  end

##
## Tasmota
##

  prometheus_scrape_targets_tasmota_exporter "Office Desk" do
    instance "http://192.168.0.207/"
  end