define(
  :ppa,
  user: nil,
) do
  node.validate! do
    {
      os: {
        name: string,
        release: string,
      },
    }
  end
  repository = "ppa:#{params[:user]}/#{params[:name]}"
  os_name = node[:os][:name]
  os_release = node[:os][:release]
  source_list_path = "/etc/apt/sources.list.d/#{params[:user]}-#{os_name}-#{params[:name]}-#{os_release}.list"
  execute "add-apt-repository -y #{repository}" do
    not_if "test -e #{source_list_path}"
  end
end