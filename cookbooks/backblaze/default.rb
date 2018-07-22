require 'shellwords'

package 'restic'

define(
	:backblaze,
	account_id: nil,
	account_key: nil,
	bucket: nil,
	password: nil,
	backup_path: nil,
	cron_minute: 0,
	cron_hour: 6,
	keep_hourly: 24,
	keep_daily: 7,
	keep_weekly: 4,
	keep_monthly: 12,
	keep_yearly: 5,
	user: 'root',
) do
	bucket = if params[:bucket]
		params[:bucket]
	else
		params[:name]
	end
	user = params[:user]
	user_home = run_command("getent passwd #{user}").stdout.split(':')[5]
	password_file_path = "#{user_home}/.restic_password-#{bucket}"
	password = params[:password]
	backup_path = params[:backup_path]
	keep_hourly = params[:keep_hourly]
	keep_daily = params[:keep_daily]
	keep_weekly = params[:keep_weekly]
	keep_monthly = params[:keep_monthly]
	keep_yearly = params[:keep_yearly]
	cron_minute = params[:cron_minute]
	cron_hour = params[:cron_hour]

	env = {
		RESTIC_REPOSITORY: "b2:#{bucket}",
		B2_ACCOUNT_ID: params[:account_id],
		B2_ACCOUNT_KEY: params[:account_key],
		RESTIC_PASSWORD_FILE: password_file_path,
	}

	restic_cmd = "/usr/bin/sudo -u #{user} #{env.to_a.map{|key, value| "#{key}=#{Shellwords.shellescape(value)}"}.join(" ")} /usr/bin/restic --quiet"

	file password_file_path do
		mode '600'
		owner user
		content password
	end

	execute "#{restic_cmd} init" do
		not_if "#{restic_cmd} snapshots"
	end

	backup_cmd = "#{restic_cmd} backup #{Shellwords.shellescape(backup_path)}"
	forget_cmd = "#{restic_cmd} forget --prune --keep-hourly #{keep_hourly} --keep-daily #{keep_daily} --keep-weekly #{keep_weekly} --keep-monthly #{keep_monthly} --keep-yearly #{keep_yearly}"
	check_cmd = "#{restic_cmd} check"

	file "/etc/cron.d/restic-#{bucket}" do
		mode '600'
		owner 'root'
		group 'root'
		content "#{cron_minute} #{cron_hour} * * * root #{backup_cmd} && #{forget_cmd} && #{check_cmd}\n"
	end
end