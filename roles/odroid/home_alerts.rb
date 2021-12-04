# Brown

prometheus_scrape_targets "brown_windows_exporter" do
  targets [
    {
      hosts: ["192.168.0.221:9182"],
      labels: {
        instance: "brown.local:9182",
        job: "windows_exporter",
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
        job: "node_exporter",
      },
    },
  ]
end

# Odroid

prometheus_scrape_targets "odroid_node_exporter" do
  targets [
    {
      hosts: ["127.0.0.1:9100"],
      labels: {
        instance: "odroid.local:9100",
        job: "node_exporter",
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

# Office

prometheus_scrape_targets "office_sensors" do
  targets [
    {
      hosts: ["192.168.0.138:9090"],
      labels: {
        instance: "office_sensors.local:9090",
        job: "sensor",
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

# Living Room

prometheus_scrape_targets "living_room_sensors" do
  targets [
    {
      hosts: ["192.168.0.124:9090"],
      labels: {
        instance: "living_room_sensors:9090",
        job: "sensor",
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

# Stogare

prometheus_rules "storage_camera" do
  alerting_rules [
    {
      alert: "StorageCameraDown",
      expr: 'up{instance="http://192.168.0.171/"} < 1',
    },
  ]
end