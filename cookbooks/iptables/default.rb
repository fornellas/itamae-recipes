define(
  :iptables_rule,
  table: nil,
  rule: nil,
) do
  table = params[:table]
  rule = params[:rule]

  execute "/sbin/iptables -t #{table} -A #{rule}" do
    user "root"
    not_if "/sbin/iptables -t #{table} -C #{rule}"
    notifies :run, "execute[iptables-save]", :immediately
  end

  execute "iptables-save" do
    action :nothing
    user "root"
    command = "/sbin/iptables-save > /etc/iptables/rules.v4"
  end
end

define(
  :iptables_rule_drop_not_user,
  user: nil,
  port: nil,
) do
  user = params[:user]
  port = params[:port]
  iptables_rule "Drop not #{user} to 127.0.0.1:#{port}" do
    table "filter"
    rule "OUTPUT -d 127.0.0.1 -p tcp -m tcp --dport #{port} -m owner ! --uid-owner #{user} -j DROP"
  end
end
