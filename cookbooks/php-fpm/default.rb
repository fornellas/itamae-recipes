php_major_version = "7"
php_minor_version = "2"
php_version = "#{php_major_version}.#{php_minor_version}"

package "php#{php_version}-fpm"

file "/etc/php/#{php_version}/fpm/pool.d/www.conf" do
  action :delete
end

remote_file "/etc/php/#{php_version}/fpm/conf.d/11-custom-opcache.ini" do
  mode "644"
  owner "root"
  group "root"
  source "files/etc/php/fpm/conf.d/11-custom-opcache.ini"
  notifies :restart, "service[php#{php_version}-fpm]", :immediately
end

service "php#{php_version}-fpm" do
  action [:enable, :start]
end
