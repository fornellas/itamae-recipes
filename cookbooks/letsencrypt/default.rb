email = "fabio.ornellas@gmail.com"

include_recipe "../nginx"
include_recipe "../backblaze"

package "python3-certbot-nginx"
package "certbot"

backblaze "#{node["fqdn"].tr(".", "-")}-letsencrypt" do
  backup_paths ["/etc/letsencrypt"]
end

define :letsencrypt, domain: nil do
  domain = if params[:domain]
      params[:domain]
    else
      params[:name]
    end
  first_domain = domain.split(",").first
  domain_file = first_domain
  if domain_file.start_with? "*."
    domain_file = domain_file.delete_prefix "*."
  end
  certificate_files = [
    "/etc/letsencrypt/live/#{domain_file}/fullchain.pem",
    "/etc/letsencrypt/live/#{domain_file}/privkey.pem",
  ]
  # FIXME for wildcard certificates, this must be manually done:
  # certbot certonly -d *.example.com -m $email --agree-tos --manual --preferred-challenges dns
  execute "/usr/bin/certbot certonly -d #{domain} --nginx -n -m #{email} --agree-tos " do
    user "root"
    not_if "#{certificate_files.map { |f| "test -f #{f}" }.join(" && ")}"
  end
end
