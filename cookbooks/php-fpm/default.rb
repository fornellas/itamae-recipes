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

  file "/etc/php/#{php_version}/fpm/php.ini" do
    action :edit
    block do |content|
      new_content = []
      content.split("\n").each do |line|
        if line.match(/^memory_limit /) then
          new_content << "memory_limit = 256M"
        else
          new_content << line
        end
      end
      content.replace(new_content.join("\n"))
    end
  end

  service "php#{php_version}-fpm" do
    action [:enable, :start]
  end
end