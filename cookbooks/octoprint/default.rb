include_recipe "../group_add"

home_path = '/var/lib/octoprint'
port = 5000
git_repo_url = "https://github.com/foosel/OctoPrint.git"
domain = 'octoprint.sigstop.co.uk'

basedir_path = "#{home_path}/.octoprint"
configfile_path = "#{basedir_path}/config.yaml"
git_repo_path = "#{home_path}/OctoPrint"
virtualenv_path = "#{home_path}/virtualenv"
unix_chkpwd_wrapper_path = "#{home_path}/unix_chkpwd_wrapper.sh"

package 'python-pip'
package 'python-dev'
package 'python-setuptools'
package 'python-virtualenv'
package 'git'
package 'libyaml-dev'
package 'build-essential'

group 'octoprint'
user 'octoprint' do
	gid 'octoprint'
	home home_path
	system_user true
	shell '/usr/sbin/nologin'
	create_home true
end
group_add 'octoprint' do
	groups ['tty', 'dialout']
end

execute "git clone #{git_repo_url} #{git_repo_path}" do
	user 'octoprint'
	cwd home_path
	not_if <<~EOF
		git -C #{git_repo_path} remote get-url --all origin | grep -E ^#{
			Shellwords.shellescape(Regexp.escape(git_repo_url))
		}\\$
	EOF
end

execute "virtualenv #{virtualenv_path}" do
	user 'octoprint'
	cwd home_path
	not_if "#{virtualenv_path}/bin/python -V"
end

execute "#{virtualenv_path}/bin/python setup.py install" do
	user 'octoprint'
	cwd git_repo_path
	not_if "#{virtualenv_path}/bin/pip list | grep -E '^OctoPrint +'"
end

execute "mkdir #{basedir_path}" do
	user 'octoprint'
	not_if "test -d #{basedir_path}"
end

template "/etc/sudoers.d/octoprint" do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		unix_chkpwd_wrapper_path: unix_chkpwd_wrapper_path,
	)
end

remote_file configfile_path do
	mode '644'
	owner 'octoprint'
	group 'octoprint'
	not_if "test -e #{configfile_path}"
end

remote_file '/etc/init.d/octoprint' do
	mode '755'
	owner 'root'
	group 'root'
end

template "/etc/default/octoprint" do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		octoprint_user: 'octoprint',
		basedir: basedir_path,
		configfile: configfile_path,
		port: port,
		daemon: "#{virtualenv_path}/bin/octoprint",
	)
	notifies :restart, 'service[octoprint]', :immediately
end

service "octoprint" do
	action :enable
end

include_recipe "../nginx"

remote_file unix_chkpwd_wrapper_path do
	mode '755'
	owner 'root'
	group 'root'
end

package "libnginx-mod-http-auth-pam"

template "/etc/pam.d/octoprint" do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		unix_chkpwd_wrapper_path: unix_chkpwd_wrapper_path,
	)
end

template '/etc/nginx/sites-enabled/octoprint' do
	mode '644'
	owner 'root'
	group 'root'
	variables(
		domain: domain,
		port: port,
	)
	notifies :restart, 'service[nginx]', :immediately
end