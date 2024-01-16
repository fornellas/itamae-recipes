require 'yaml'

directory "/etc/prometheus" do
  owner "root"
  group "root"
  mode "755"
end

##
## blackbox_exporter
##

  directory "/etc/prometheus/blackbox_http_2xx.d" do
    owner "root"
    group "root"
    mode "755"
  end

  # prometheus_scrape_targets_blackbox_http_2xx "foo" do
  #   targets [
  #     {
  #       # The targets specified by the static config.
  #       hosts: [
  #         "host1:123",
  #         "host2:456",
  #       ],
  #       # Labels assigned to all metrics scraped from the targets.
  #       # Optional
  #       labels: {
  #         a: "b",
  #         c: "d",
  #       },
  #     }
  #   ]
  # end
  define(
    :prometheus_scrape_targets_blackbox_http_2xx,
    targets: [],
  ) do
    name = params[:name]
    targets = params[:targets]

    targets.each do |target|
      if target.has_key? :labels and target[:labels].has_key? :job
        raise UserInputError, "target[:labels] can not have job key: #{target}"
      end
    end

    rule_path = "/etc/prometheus/blackbox_http_2xx.d/#{name}.yml"

    template rule_path do
      mode "644"
      owner "root"
      group "root"
      source "templates/etc/prometheus/file_sd.d/template.yml"
      variables(
        targets: targets,
      )
      notifies :restart, "service[prometheus]", :delayed
    end
  end

  directory "/etc/prometheus/blackbox_http_302.d" do
    owner "root"
    group "root"
    mode "755"
  end

  # prometheus_scrape_targets_blackbox_http_302 "foo" do
  #   targets [
  #     {
  #       # The targets specified by the static config.
  #       hosts: [
  #         "host1:123",
  #         "host2:456",
  #       ],
  #       # Labels assigned to all metrics scraped from the targets.
  #       # Optional
  #       labels: {
  #         a: "b",
  #         c: "d",
  #       },
  #     }
  #   ]
  # end
  define(
    :prometheus_scrape_targets_blackbox_http_302,
    targets: [],
  ) do
    name = params[:name]
    targets = params[:targets]

    targets.each do |target|
      if target.has_key? :labels and target[:labels].has_key? :job
        raise UserInputError, "target[:labels] can not have job key: #{target}"
      end
    end

    rule_path = "/etc/prometheus/blackbox_http_302.d/#{name}.yml"

    template rule_path do
      mode "644"
      owner "root"
      group "root"
      source "templates/etc/prometheus/file_sd.d/template.yml"
      variables(
        targets: targets,
      )
      notifies :restart, "service[prometheus]", :delayed
    end
  end

  directory "/etc/prometheus/blackbox_http_401.d" do
    owner "root"
    group "root"
    mode "755"
  end

  # prometheus_scrape_targets_blackbox_http_401 "foo" do
  #   targets [
  #     {
  #       # The targets specified by the static config.
  #       hosts: [
  #         "host1:123",
  #         "host2:456",
  #       ],
  #       # Labels assigned to all metrics scraped from the targets.
  #       # Optional
  #       labels: {
  #         a: "b",
  #         c: "d",
  #       },
  #     }
  #   ]
  # end
  define(
    :prometheus_scrape_targets_blackbox_http_401,
    targets: [],
  ) do
    name = params[:name]
    targets = params[:targets]

    targets.each do |target|
      if target.has_key? :labels and target[:labels].has_key? :job
        raise UserInputError, "target[:labels] can not have job key: #{target}"
      end
    end

    rule_path = "/etc/prometheus/blackbox_http_401.d/#{name}.yml"

    template rule_path do
      mode "644"
      owner "root"
      group "root"
      source "templates/etc/prometheus/file_sd.d/template.yml"
      variables(
        targets: targets,
      )
      notifies :restart, "service[prometheus]", :delayed
    end
  end

  directory "/etc/prometheus/blackbox_ssh_banner.d" do
    owner "root"
    group "root"
    mode "755"
  end

  # prometheus_scrape_targets_blackbox_ssh_banner "foo" do
  #   targets [
  #     {
  #       # The targets specified by the static config.
  #       hosts: [
  #         "host1:123",
  #         "host2:456",
  #       ],
  #       # Labels assigned to all metrics scraped from the targets.
  #       # Optional
  #       labels: {
  #         a: "b",
  #         c: "d",
  #       },
  #     }
  #   ]
  # end
  define(
    :prometheus_scrape_targets_blackbox_ssh_banner,
    targets: [],
  ) do
    name = params[:name]
    targets = params[:targets]

    targets.each do |target|
      if target.has_key? :labels and target[:labels].has_key? :job
        raise UserInputError, "target[:labels] can not have job key: #{target}"
      end
    end

    rule_path = "/etc/prometheus/blackbox_ssh_banner.d/#{name}.yml"

    template rule_path do
      mode "644"
      owner "root"
      group "root"
      source "templates/etc/prometheus/file_sd.d/template.yml"
      variables(
        targets: targets,
      )
      notifies :restart, "service[prometheus]", :delayed
    end
  end

##
## brother_exporter
##

  directory "/etc/prometheus/brother_exporter.d" do
    owner "root"
    group "root"
    mode "755"
  end

  # prometheus_scrape_targets_brother_exporter "foo" do
  #   targets [
  #     {
  #       # The targets specified by the static config.
  #       hosts: [
  #         "host1:123",
  #         "host2:456",
  #       ],
  #       # Labels assigned to all metrics scraped from the targets.
  #       # Optional
  #       labels: {
  #         a: "b",
  #         c: "d",
  #       },
  #     }
  #   ]
  # end
  define(
    :prometheus_scrape_targets_brother_exporter,
    instance: nil,
  ) do
    name = params[:name]
    instance = params[:instance]

    rule_path = "/etc/prometheus/brother_exporter.d/#{name}.yml"

    template rule_path do
      mode "644"
      owner "root"
      group "root"
      source "templates/etc/prometheus/file_sd.d/template.yml"
      variables(targets: [{hosts: [instance]}])
      notifies :restart, "service[prometheus]", :delayed
    end

    prometheus_rules "brother_exporter_#{name}" do
      alerting_rules [
        {
          alert: "Brother Exporter: #{name} down",
          expr: <<~EOF,
            group(
              up{
                instance="#{instance}",
              } < 1
            )
          EOF
          for: "2m",
        },
      ]
    end
  end

##
## prometheus
##

  directory "/etc/prometheus/rules.d" do
    owner "root"
    group "root"
    mode "755"
  end

  # prometheus_rules "foo" do
  #   # How often rules in the group are evaluated.
  #   # Optional.
  #   interval "1m"
  #   # Limit the number of alerts an alerting rule and series a recording
  #   # rule can produce. 0 is no limit.
  #   # Optional.
  #   limit 0
  #   # Alerting Rules
  #   alerting_rules [
  #     {
  #       # The name of the alert. Must be a valid label value.
  #       # Required.
  #       alert: "alert name",
  #       # The PromQL expression to evaluate. Every evaluation cycle this is
  #       # evaluated at the current time, and all resultant time series become
  #       # pending/firing alerts.
  #       # Required.
  #       expr: "up < 1",
  #       # Alerts are considered firing once they have been returned for this long.
  #       # Alerts which have not yet fired for long enough are considered pending.
  #       # Optional.
  #       for: "3m",
  #       # Labels to add or overwrite for each alert.
  #       # Optional.
  #       labels: {
  #         a: "b",
  #         c: "d",
  #       },
  #       # Annotations to add to each alert.
  #       # Optional.
  #       annotations: {
  #         e: "f",
  #         g: "h",
  #       },
  #     },
  #   ]
  #   # Recording Rules
  #   recording_rules [
  #     {
  #       # The name of the time series to output to. Must be a valid metric name.
  #       # Required.
  #       record: "record name",
  #       # The PromQL expression to evaluate. Every evaluation cycle this is
  #       # evaluated at the current time, and the result recorded as a new set of
  #       # time series with the metric name as given by 'record'.
  #       # Required.
  #       expr: "up < 1",
  #       # Labels to add or overwrite before storing the result.
  #       # Optional.
  #       labels: {
  #         a: "b",
  #         c: "d",
  #       },
  #     },
  #   ]
  # end
  define(
    :prometheus_rules,
    interval: nil,
    limit: nil,
    alerting_rules: [],
    recording_rules: [],
  ) do
    name = params[:name]
    interval = params[:interval]
    limit = params[:limit]
    alerting_rules = params[:alerting_rules]
    recording_rules = params[:recording_rules]

    rule_path = "/etc/prometheus/rules.d/#{name}.yml"

    template rule_path do
      mode "644"
      owner "root"
      group "root"
      source "templates/etc/prometheus/rules.d/template.yml"
      variables(
        group_name: name,
        interval: interval,
        limit: limit,
        alerting_rules: alerting_rules,
        recording_rules: recording_rules,
      )

      notifies :restart, "service[prometheus]", :delayed
    end
  end

  directory "/etc/prometheus/file_sd.d" do
    owner "root"
    group "root"
    mode "755"
  end

  # prometheus_scrape_targets "foo" do
  #   targets [
  #     {
  #       # The targets specified by the static config.
  #       hosts: [
  #         "host1:123",
  #         "host2:456",
  #       ],
  #       # Labels assigned to all metrics scraped from the targets.
  #       # Optional
  #       labels: {
  #         a: "b",
  #         c: "d",
  #       },
  #     }
  #   ]
  # end
  define(
    :prometheus_scrape_targets,
    targets: [],
  ) do
    name = params[:name]
    targets = params[:targets]

    targets.each do |target|
      unless target.has_key? :labels
        raise UserInputError, "target missing :labels key: #{target}"
      end
      unless target[:labels].has_key? :job
        raise UserInputError, "target[:labels] missing job key: #{target}"
      end
    end

    rule_path = "/etc/prometheus/file_sd.d/#{name}.yml"

    template rule_path do
      mode "644"
      owner "root"
      group "root"
      source "templates/etc/prometheus/file_sd.d/template.yml"
      variables(
        targets: targets,
      )
      notifies :restart, "service[prometheus]", :delayed
    end
  end

  directory "/etc/prometheus/scrape_config.d" do
    owner "root"
    group "root"
    mode "755"
  end

  # prometheus_scrape_config "foo" do
  #   scrape_config(
  #     job_name: "foo"
  #     static_configs: [
  #       {
  #         targets: [
  #           "example.com:9090",
  #         ],
  #       },
  #     ]
  #   )
  # end
  define(
    :prometheus_scrape_config,
    scrape_configs: [],
  ) do
    name = params[:name]
    content = {
      "scrape_configs" => params[:scrape_configs].map do |scrape_config|
        scrape_config.to_hash
      end.to_a
    }

    file "/etc/prometheus/scrape_config.d/#{name}.yml" do
      mode "644"
      owner "root"
      group "root"
      content YAML.dump content
      notifies :restart, "service[prometheus]", :delayed
    end
  end