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

prometheus_scrape_targets "brown_windows_exporter" do
  targets [
    {
      hosts: ["192.168.0.221:9182"],
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
      hosts: ["192.168.0.221:9100"],
      labels: {
        instance: "brown.local:9100",
        exporter: "node_exporter",
      },
    },
  ]
end

##
## Odroid
##

prometheus_scrape_targets "odroid_node_exporter" do
  targets [
    {
      hosts: ["127.0.0.1:9100"],
      labels: {
        instance: "odroid.local:9100",
        exporter: "node_exporter",
      },
    },
  ]
end

prometheus_rules "odroid" do
  alerting_rules [
    {
      alert: "OdroidDown",
      expr: 'up{instance="odroid.local:9100"} < 1',
    },
  ]
end

##
## Office
##

prometheus_scrape_targets "office_sensors" do
  targets [
    {
      hosts: ["192.168.0.138:9090"],
      labels: {
        instance: "office_sensors.local:9090",
        exporter: "sensor",
      },
    },
  ]
end

prometheus_rules "office_sensors" do
  alerting_rules [
    {
      alert: "OfficeSensorDown",
      expr: 'up{instance="office_sensors.local:9090"} < 1',
    },
    {
      alert: "OfficeLowTemp",
      expr: 'temperature_celsius{room="office"} < 20',
    },
    {
      alert: "OfficeHighCO2",
      expr: 'co2_concentration_ppm{room="office"} > 1600',
    },
  ]
end

##
## Living Room
##

prometheus_scrape_targets "living_room_sensors" do
  targets [
    {
      hosts: ["192.168.0.124:9090"],
      labels: {
        instance: "living_room_sensors:9090",
        exporter: "sensor",
      },
    },
  ]
end

prometheus_rules "living_room_sensors" do
  alerting_rules [
    {
      alert: "LivingRoomSensorDown",
      expr: 'up{instance="living_room_sensors.local:9090"} < 1',
    },
    {
      alert: "LivingRoomLowTemp",
      expr: 'temperature_celsius{room="living room"} < 20',
    },
  ]
end

##
## Storage
##

prometheus_scrape_targets_blackbox_http_2xx "storage" do
  targets [
    {
      hosts: ["http://192.168.0.171/"],
      labels: [
        instance: "storage_camera.local"
      ],
    }
  ]
end

prometheus_rules "storage_camera" do
  alerting_rules [
    {
      alert: "StorageCameraDown",
      expr: 'up{instance="storage_camera.local"} < 1',
    },
  ]
end
