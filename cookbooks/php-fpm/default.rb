php_major_version = "7"
php_minor_version = "2"
php_version = "#{php_major_version}.#{php_minor_version}"

package "php#{php_version}-fpm"

file "/etc/php/#{php_version}/fpm/pool.d/www.conf" do
	action :delete
end

service "php#{php_version}-fpm"