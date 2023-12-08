package "netfilter-persistent"
package "iptables-persistent"

service "netfilter-persistent" do
  action [:enable, :start]
end

execute "netfilter-persistent save" do
  action :nothing
  user "root"
end

define(
  :iptables,
  table: nil,
  command: nil,
  chain: nil,
  rule_specification: nil,
) do
  table = params[:table]

  chain = params[:chain]

  case params[:command]
  when :append
    command = "-A #{chain}"
  when :prepend
    command = "-I #{chain} 1"
  else
    raise ArgumentError, "command must be either :append or :prepend"
  end

  rule_specification = params[:rule_specification]

  execute "iptables --table #{table} #{command} #{rule_specification}" do
    user "root"
    not_if "iptables -t #{table} -C #{chain} #{rule_specification}"
    notifies :run, "execute[netfilter-persistent save]", :immediately
  end
end


define(
  :iptables_rule_drop_not_user,
  users: [],
  port: nil,
) do
  users = params[:users]
  port = params[:port]

  iptables "Accept OUTPUT established and related" do
    table "filter"
    command :append
    chain "OUTPUT"
    rule_specification "--match conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
    notifies :run, "execute[netfilter-persistent save]", :immediately
  end

  iptables "Drop not #{users.join("|")} to 127.0.0.1:#{port}" do
    table "filter"
    command :append
    chain "OUTPUT"
    rule_specification "-d 127.0.0.1 -p tcp -m tcp --dport #{port} #{users.map { |user| "-m owner ! --uid-owner #{user}" }.join(" ")} -j DROP"
    notifies :run, "execute[netfilter-persistent save]", :immediately
  end
end
