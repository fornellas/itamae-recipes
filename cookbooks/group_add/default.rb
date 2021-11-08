define :group_add, groups: nil do
  username_group_add = params[:name]
  params[:groups].each do |group|
    execute "gpasswd -a #{username_group_add} #{group}" do
      user "root"
      command "gpasswd -a #{username_group_add} #{group}"
      not_if "groups #{username_group_add} | cut -d : -f2- | tr \\  \\\\n | grep -Ev '^$' | grep -E '^#{group}$'"
    end
  end
end
