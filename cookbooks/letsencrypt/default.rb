email = "fabio.ornellas@gmail.com"

include_recipe "../nginx"
include_recipe "../backblaze"

package 'python3-certbot-nginx'
package 'certbot'

backblaze "#{node['fqdn'].tr('.', '-')}-letsencrypt" do
	backup_paths ["/etc/letsencrypt"]
end

define :letsencrypt, domain: nil do
	domain = if params[:domain]
		params[:domain]
	else
		params[:name]
	end
	certificate_files = [
		"/etc/letsencrypt/live/#{domain}/fullchain.pem",
		"/etc/letsencrypt/live/#{domain}/privkey.pem",
	]
	execute "/usr/bin/certbot certonly -d #{domain} --nginx -n -m #{email} --agree-tos " do
		user 'root'
		not_if "#{certificate_files.map{|f| "test -f #{f}"}.join(' && ')}"
	end
end