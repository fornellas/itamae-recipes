first_line = "auth sufficient pam_listfile.so item=tty sense=allow file=/etc/securetty"

file "/etc/pam.d/common-auth" do
  action :edit
  block do |content|
  	if content.split("\n").first != first_line
  		content.replace("#{first_line}\n#{content}")
	end
  end
end