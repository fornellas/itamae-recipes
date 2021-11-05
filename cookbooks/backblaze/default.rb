require 'shellwords'

cache_path = "/var/cache/restic"

package 'restic'

directory cache_path do
    owner 'root'
    group 'root'
    mode '755'
end

define(
    :backblaze,
    command_before: '/bin/true',
    bucket: nil,
    backup_paths: nil,
    backup_exclude: nil,
    backup_cmd_stdout: nil,
    backup_cmd_stdout_filename: nil,
    command_after: '/bin/true',
    cron_minute: 0,
    cron_hour: 4,
    keep_hourly: 24,
    keep_daily: 7,
    keep_weekly: 4,
    keep_monthly: 12,
    keep_yearly: 5,
    user: 'root',
    bin_path: nil,
) do
    command_before = params[:command_before]
    bucket = if params[:bucket]
        params[:bucket]
    else
        params[:name]
    end
    user = params[:user]
    bin_path = params[:bin_path]
    if not bin_path
        bin_path = run_command("getent passwd #{user}").stdout.split(':')[5]
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
                }
            }
        }
    end
    password = node[:backblaze][bucket][:password]
    backup_paths = params[:backup_paths]
    backup_exclude = params[:backup_exclude]
    backup_cmd_stdout = params[:backup_cmd_stdout]
    backup_cmd_stdout_filename = params[:backup_cmd_stdout_filename]
    command_after = params[:command_after]
    keep_hourly = params[:keep_hourly]
    keep_daily = params[:keep_daily]
    keep_weekly = params[:keep_weekly]
    keep_monthly = params[:keep_monthly]
    keep_yearly = params[:keep_yearly]
    cron_minute = params[:cron_minute]
    cron_hour = params[:cron_hour]

    env = {
        RESTIC_REPOSITORY: "b2:#{bucket}",
        B2_ACCOUNT_ID: node[:backblaze][bucket][:account_id],
        B2_ACCOUNT_KEY: node[:backblaze][bucket][:account_key],
        RESTIC_PASSWORD_FILE: password_file_path,
    }

    file restic_script_path do
        mode '700'
        owner user
        content <<~EOF
            #!/bin/sh
            /usr/bin/sudo -u #{user} #{env.to_a.map{|key, value| "#{key}=#{Shellwords.shellescape(value)}"}.join(" ")} /usr/bin/restic --quiet --cache-dir #{Shellwords.shellescape(restic_cache_path)} \"$@\"
        EOF
    end

    file password_file_path do
        mode '600'
        owner user
        content password
    end

    directory restic_cache_path do
        owner user
        mode '700'
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
        backup_cmd << "#{restic_script_path} backup #{exclude} #{backup_paths.map{|path| Shellwords.shellescape(path)}.join(' ')}"
    end
    if backup_cmd_stdout
        backup_cmd << "#{backup_cmd_stdout} | #{restic_script_path} backup --stdin --stdin-filename #{Shellwords.shellescape(backup_cmd_stdout_filename)}"
    end
    backup_cmd = backup_cmd.join(' && ')
    forget_cmd = "#{restic_script_path} forget --prune --keep-hourly #{keep_hourly} --keep-daily #{keep_daily} --keep-weekly #{keep_weekly} --keep-monthly #{keep_monthly} --keep-yearly #{keep_yearly}"
    check_cmd = "#{restic_script_path} check"

    file restic_cron_script_path do
        mode '700'
        owner user
        content <<~EOF
            #!/bin/bash
            EXIT=0
            if #{command_before}
            then
                if #{backup_cmd}
                then
                    if #{forget_cmd}
                    then
                        if date +%w | grep -qE ^0$
                        then
                            if ! #{check_cmd}
                            then
                                echo Check failed! 1>&2
                                EXIT=1
                            fi
                        fi
                    else
                        echo Forget failed! 1>&2
                        EXIT=1
                    fi
                else
                    echo Backup failed! 1>&2
                    EXIT=1
                fi
                if ! #{command_after}
                then
                    echo After hook failed! 1>&2
                    EXIT=1
                fi
            else
                echo Before hook failed! 1>&2
                EXIT=1
            fi
            exit $EXIT
        EOF
    end

    file "/etc/cron.d/restic-#{bucket}" do
        mode '644'
        owner 'root'
        group 'root'
        content "#{cron_minute} #{cron_hour} * * * root #{restic_cron_script_path}\n"
    end
end