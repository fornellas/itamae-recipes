email = "fabio.ornellas@gmail.com"

package 'postfix'

template "/etc/postfix/main.cf" do
	owner 'root'
	group 'root'
	mode '644'
	variables(myhostname: node['fqdn'])
	notifies :restart, 'service[postfix]', :immediately
end

service 'postfix'

file "/etc/aliases" do
	action :edit
	block do |content|
		newalias = "root: #{email}"
		unless content.include?(newalias)
			content.replace("#{content}\nnewalias")
		end
	end
	notifies :run, 'execute[/usr/bin/newaliases]', :immediately
end

execute "/usr/bin/newaliases" do
	user 'root'
	action :nothing
end

package 'mailutils'