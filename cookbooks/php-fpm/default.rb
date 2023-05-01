include_recipe "../../cookbooks/php-ppa"

define(:php_fpm) do
  php_version = params[:name]

  package "php#{php_version}-fpm"

  service "php#{php_version}-fpm" do
    action [:enable, :start]
  end
end