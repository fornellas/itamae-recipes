domain = "vpn.sigstop.co.uk"

package 'openvpn'

# Certificates
# certbot certonly -d vpn.sigstop.co.uk -n -m fabio.ornellas@gmail.com --agree-tos --standalone
  # --pre-hook 'service openvpn stop' \ 
  # --post-hook 'service openvpn start'

# /etc/sysctl.d/forwarding.conf
# net.ipv4.conf.all.forwarding=1

# NAT
# Chain POSTROUTING (policy ACCEPT 93598 packets, 5616K bytes)
#  pkts bytes target     prot opt in     out     source               destination         
#  986K   64M MASQUERADE  all  --  *      eth0    0.0.0.0/0            0.0.0.0/0           

remote_file "/etc/default/openvpn" do
	mode '644'
	owner 'root'
	group 'root'
	notifies :restart, 'service[openvpn]'
end

service 'openvpn'