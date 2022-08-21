include_recipe "../../cookbooks/php-ppa"

define(:php_fpm) do
  php_version = params[:name]

  package "php#{php_version}-fpm"

  # FIXME
  # WARNING: Nothing matches the include pattern '/etc/php/8.0/fpm/pool.d/*.conf' from /etc/php/8.0/fpm/php-fpm.conf at line 145.
  # ERROR: No pool defined. at least one pool section must be specified in config fil
  # file "/etc/php/#{php_version}/fpm/pool.d/www.conf" do
  #   action :delete
  # end


  remote_file "/etc/php/#{php_version}/fpm/php.ini" do
    mode "644"
    owner "root"
    group "root"
    source "files/etc/php/fpm/php.ini"
    notifies :restart, "php#{php_version}-fpm"
  end

  service "php#{php_version}-fpm" do
    action [:enable, :start]
  end
end