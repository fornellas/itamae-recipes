require "shellwords"
include_recipe "../../cookbooks/monitoring"

cache_path = "/var/cache/restic"

package "restic"

directory cache_path do
  owner "root"
  group "root"
  mode "755"
end

define(
  :backblaze,
  command_before: "/bin/true",
  bucket: nil,
  backup_paths: nil,
  backup_exclude: nil,
  backup_cmd_stdout: nil,
  backup_cmd_stdout_filename: nil,
  command_after: "/bin/true",
  keep_hourly: 24,
  keep_daily: 7,
  keep_weekly: 4,
  keep_monthly: 12,
  keep_yearly: 5,
  user: "root",
  group: "root",
  bin_path: nil,
) do
  bucket = if params[:bucket]
      params[:bucket]
    else
      params[:name]
    end
  user = params[:user]
  group = params[:group]
  command_before = "/usr/bin/sudo -u #{user} #{params[:command_before]}"
  bin_path = params[:bin_path]
  if not bin_path
    bin_path = run_command("getent passwd #{user}").stdout.split(":")[5]
  end
  restic_script_path = "#{bin_path}/.restic-#{bucket}"
  restic_cron_script_path = "#{bin_path}/.restic-#{bucket}-cron"
  password_file_path = "#{bin_path}/.restic-#{bucket}-password"
  restic_cache_path = "#{cache_path}/#{user}-#{bucket}"
  node.validate! do
    {
      backblaze: {
        bucket => {
          account_id: string,
          account_key: string,
          password: string,
        },
      },
    }
  end
  password = node[:backblaze][bucket][:password]
  backup_paths = params[:backup_paths]
  backup_exclude = params[:backup_exclude]
  backup_cmd_stdout = params[:backup_cmd_stdout]
  backup_cmd_stdout_filename = params[:backup_cmd_stdout_filename]
  command_after = "/usr/bin/sudo -u #{user} #{params[:command_after]}"
  keep_hourly = params[:keep_hourly]
  keep_daily = params[:keep_daily]
  keep_weekly = params[:keep_weekly]
  keep_monthly = params[:keep_monthly]
  keep_yearly = params[:keep_yearly]

  env = {
    RESTIC_REPOSITORY: "b2:#{bucket}",
    B2_ACCOUNT_ID: node[:backblaze][bucket][:account_id],
    B2_ACCOUNT_KEY: node[:backblaze][bucket][:account_key],
    RESTIC_PASSWORD_FILE: password_file_path,
  }

  file restic_script_path do
    mode "700"
    owner user
    group group
    content <<~EOF
      #!/bin/sh
      /usr/bin/sudo -u #{user} #{env.to_a.map { |key, value| "#{key}=#{Shellwords.shellescape(value)}" }.join(" ")} /usr/bin/restic --quiet --cache-dir #{Shellwords.shellescape(restic_cache_path)} \"$@\"
    EOF
  end

  file password_file_path do
    mode "600"
    owner user
    group group
    content password
  end

  directory restic_cache_path do
    owner user
    group group
    mode "700"
  end

  execute "#{restic_script_path} init" do
    not_if "#{restic_script_path} snapshots"
  end

  backup_cmd = []
  if backup_paths
    exclude = ""
    if backup_exclude
      backup_exclude.each do |pattern|
        exclude += "--exclude #{Shellwords.shellescape(pattern)}"
      end
    end
    backup_cmd << "#{restic_script_path} backup #{exclude} #{backup_paths.map { |path| Shellwords.shellescape(path) }.join(" ")}"
  end
  if backup_cmd_stdout
    backup_cmd << "/usr/bin/sudo -u #{user} #{backup_cmd_stdout} | #{restic_script_path} backup --stdin --stdin-filename #{Shellwords.shellescape(backup_cmd_stdout_filename)}"
  end
  backup_cmd = backup_cmd.join(" && ")
  forget_cmd = "#{restic_script_path} forget --prune --keep-hourly #{keep_hourly} --keep-daily #{keep_daily} --keep-weekly #{keep_weekly} --keep-monthly #{keep_monthly} --keep-yearly #{keep_yearly}"
  check_cmd = "#{restic_script_path} check"
  collector_textile_prefix = "/var/lib/node_exporter/collector_textfile/restic"

  file restic_cron_script_path do
    mode "700"
    owner user
    group group
    content <<~EOF
      #!/bin/bash
      set -e
      cd #{bin_path}
      if #{command_before} ; then
        if #{backup_cmd}
        then
          if #{forget_cmd} ; then
            if date +%w | grep -qE ^0$ ; then
              if ! #{check_cmd} ; then
                echo Check failed! 1>&2
                exit 1
              fi
            fi
          else
            echo Forget failed! 1>&2
            exit 1
          fi
        else
          echo Backup failed! 1>&2
          exit 1
        fi
        if ! #{command_after} ; then
          echo After hook failed! 1>&2
          exit 1
        fi
      else
        echo Before hook failed! 1>&2
        exit 1
      fi
      echo 'backup_completion_time{bucket="#{bucket}"}' $(date +%s) > #{collector_textile_prefix}-#{bucket}
      cat #{collector_textile_prefix}-* > #{collector_textile_prefix}.prom.$$
      mv #{collector_textile_prefix}.prom.$$ #{collector_textile_prefix}.prom
    EOF
  end

  file "/etc/cron.daily/restic-#{bucket}" do
    mode "755"
    owner "root"
    group "root"
    content <<~EOF
      #!/bin/bash
      exec #{restic_cron_script_path}
    EOF
  end

  prometheus_rules "restic-#{bucket}" do
    alerting_rules [
      {
        alert: "Backup Has Not Completed Successfully Recently",
        expr: <<~EOF,
          group by (bucket)(
            (
              time()
              -
              backup_completion_time{
                bucket="#{bucket}",
              }
            ) > 3600*24*2
          )
        EOF
      },
      {
        alert: "Backup Completion Data Absent",
        expr: <<~EOF,
          group by (bucket)(
            absent(
              backup_completion_time{
                bucket="#{bucket}",
              }
            )
          )
        EOF
      },
    ]
  end
end
