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
        alert: "SSH Down",
        expr: <<~EOF,
          group by (instance) (
              up{
                  instance="#{n2p_ssh}",
                  job="blackbox_ssh_banner",
              } < 1
          )
        EOF
      },
    ]
  end

##
## Internet
##

  prometheus_scrape_targets_blackbox_http_2xx "google" do
    targets [
      {
        hosts: ["http://google.com/"],
        labels: {
          internet: "true",
        },
      },
    ]
  end

  prometheus_scrape_targets_blackbox_http_2xx "facebook" do
    targets [
      {
        hosts: ["http://facebook.com/"],
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
        labels: {
          instance: "virgin.local",
        },
      },
    ]
  end

##
## Brown
##

  brow_ip = "192.168.0.221"

  prometheus_scrape_targets "brown_windows_exporter" do
    targets [
      {
        hosts: ["#{brow_ip}:9182"],
        labels: {
          instance: "brown.local:9182",
          exporter: "windows_exporter",
        },
      },
    ]
  end

  prometheus_scrape_targets "brown_node_exporter" do
    targets [
      {
        hosts: ["#{brow_ip}:9100"],
        labels: {
          instance: "brown.local:9100",
          exporter: "node_exporter",
        },
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
          exporter: "sensor",
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
          exporter: "sensor",
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
          exporter: "power_meter",
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
        alert: "High Power Usage",
        expr: <<~EOF,
          group(
            avg_over_time(
              power_wats{
                instance="#{power_meter_instance}",
              }[1h]
            ) > 1500
          )
        EOF
      },
    ]
  end