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
  :iptables_rule,
  table: nil,
  rule: nil,
) do
  table = params[:table]
  rule = params[:rule]

  package "netfilter-persistent"

  execute "iptables -t #{table} -A #{rule}" do
    user "root"
    not_if "iptables -t #{table} -C #{rule}"
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

  iptables_rule "Accept output established and related" do
    table "filter"
    rule "OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
    notifies :run, "execute[netfilter-persistent save]", :immediately
  end

  iptables_rule "Drop not #{users.join("|")} to 127.0.0.1:#{port}" do
    table "filter"
    rule "OUTPUT -d 127.0.0.1 -p tcp -m tcp --dport #{port} #{users.map { |user| "-m owner ! --uid-owner #{user}" }.join(" ")} -j DROP"
    notifies :run, "execute[netfilter-persistent save]", :immediately
  end
end
