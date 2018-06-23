package 'postfix'

template "/etc/postfix/main.cf" do
	owner 'root'
	group 'root'
	mode '644'
	variables(myhostname: node['fqdn'])
	notifies :restart, 'service[postfix]', :immediately
end

service 'postfix'

package 'mailutils'