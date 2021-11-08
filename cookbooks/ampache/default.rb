domain = "ampache.sigstop.co.uk"
port = "443"
php_major_version = "7"
php_minor_version = "2"
home_path = "/var/lib/ampache"
ampache_version = "3.8.8"

php_version = "#{php_major_version}.#{php_minor_version}"
socket_path = "/run/php/php#{php_version}-fpm-ampache.sock"
fpm_pool_prefix = "/var/lib/ampache/Ampache"

##
## Deps
##

include_recipe "../php-fpm"

package "composer"
package "ffmpeg"
package "php#{php_version}"
package "php#{php_version}-curl"
package "php#{php_version}-gd"
package "php#{php_version}-json"
package "php#{php_version}-common"
package "php#{php_version}-mysql"
package "php#{php_version}-xml"

include_recipe "../mysql"

##
## User / Group
##

group "ampache"

user "ampache" do
  gid "ampache"
  home home_path
  system_user true
  shell "/usr/sbin/nologin"
  create_home true
end

##
## Ampache
##

directory fpm_pool_prefix do
  user "ampache"
end

execute "wget -O ampache-#{ampache_version}_all-tmp.zip https://github.com/ampache/ampache/releases/download/#{ampache_version}/ampache-#{ampache_version}_all.zip && unzip ampache-#{ampache_version}_all-tmp.zip && mv ampache-#{ampache_version}_all-tmp.zip ampache-#{ampache_version}_all.zip" do
  user "ampache"
  cwd fpm_pool_prefix
  not_if "test -f ampache-#{ampache_version}_all.zip"
end

execute "composer install --prefer-source --no-interaction && touch .composer_install_ok" do
  user "ampache"
  cwd fpm_pool_prefix
  not_if "test -f .composer_install_ok"
end

template "/etc/php/#{php_version}/fpm/pool.d/ampache.conf" do
  source "templates/etc/php/fpm/pool.d/ampache.conf"
  mode "755"
  owner "root"
  group "root"
  variables(
    socket_path: socket_path,
  )
  notifies :restart, "service[php#{php_version}-fpm]"
end

##
## Let's encrypt
##

include_recipe "../letsencrypt"

letsencrypt domain

##
## Nginx
##

include_recipe "../nginx"

package "libnginx-mod-http-auth-pam"

template "/etc/nginx/sites-enabled/ampache" do
  mode "644"
  owner "root"
  group "root"
  variables(
    domain: domain,
    port: port,
    fpm_pool_prefix: fpm_pool_prefix,
    socket_path: socket_path,
  )
  notifies :restart, "service[nginx]", :immediately
end
