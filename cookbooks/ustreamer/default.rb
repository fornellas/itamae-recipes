node.validate! do
  {
    ustreamer: {
      device: string,
      domain: string,
      port: string,
      resolution: string,
      version: string,
    },
  }
end

device = node[:ustreamer][:device]
domain = node[:ustreamer][:domain]
port = node[:ustreamer][:port]
resolution = node[:ustreamer][:resolution]
version = node[:ustreamer][:version]

home_path = "/var/lib/ustreamer"
install_path = "#{home_path}/ustreamer"

##
## Deps
##

	# build

  package "build-essential"
  package "libbsd-dev"
  package "libevent-dev"
  package "libjpeg-dev"
  package "libc6-dev"
  package 'v4l-utils'

##
## User / Group
##

  group "ustreamer"

  user "ustreamer" do
    gid "ustreamer"
    home home_path
    system_user true
    shell "/usr/sbin/nologin"
    create_home true
  end

  include_recipe "../group_add"

	group_add "ustreamer" do
	  groups [
     "video",
   ]
	end

##
## Install
##

	# git

		git install_path do
      user "ustreamer"
      revision version
		  repository "https://github.com/pikvm/ustreamer"
    end

  # make

	  make_ok_path = "#{home_path}/.make.#{version}"

	  execute "Build" do
	    command <<~EOF
	      set -e
	      cd #{install_path}
	      make
	      touch #{make_ok_path}
	    EOF
	    user "ustreamer"
	    not_if "test #{make_ok_path} -nt #{install_path}/.git/logs/HEAD"
	  end

##
## Service
##

  template "/etc/systemd/system/ustreamer.service" do
    mode "644"
    owner "root"
    group "root"
    variables(
			install_path: install_path,
			device: device,
			port: port,
			resolution: resolution,
    )
    notifies :run, "execute[systemctl daemon-reload]"
  end

  execute "systemctl daemon-reload" do
    action :nothing
    user "root"
    notifies :restart, "service[ustreamer]"
  end

  service "ustreamer" do
    action [:enable, :start]
  end

##
## Nginx
##

	# iptables

	  iptables_rule_drop_not_user "Drop not www-data" do
	    users ["www-data"]
	    port port
	  end

  # Let's Encrypt

    include_recipe "../letsencrypt"
    letsencrypt domain

  # Nginx

    include_recipe "../nginx"

  # Auth

    remote_file "/etc/pam.d/ustreamer" do
      mode "644"
      owner "root"
      group "root"
    end

    template "/etc/nginx/sites-enabled/ustreamer" do
      mode "644"
      owner "root"
      group "root"
      variables(
        domain: domain,
        port: port,
      )
      notifies :restart, "service[nginx]", :immediately
    end