require "etc"
require "itamae/plugin/resource/authorized_keys"
require "shellwords"
include_recipe "../group_add"

username = Etc.getlogin
shellname = Etc.getpwuid.shell
home_dir = Etc.getpwuid.dir
shadow_encrypted_password = `sudo getent shadow #{username} | cut -d: -f2`.chomp
raise unless $?.success?
groupname = Etc.getgrgid.name

define :user_shadow, encrypted_password: nil do
  username_user_shadow = params[:name]
  user_shadow_encrypted_password = params[:encrypted_password]
  execute "usermod -p #{Shellwords.shellescape(user_shadow_encrypted_password)} #{username_user_shadow}" do
    user "root"
    not_if <<~EOF
             getent shadow #{username_user_shadow} \
				| cut -d: -f2 \
				| grep ^#{Shellwords.shellescape(Regexp.escape(user_shadow_encrypted_password))}\\$
           EOF
  end
end

group groupname

user username do
  gid groupname
  home home_dir
  shell shellname
  create_home true
end

user_shadow username do
  encrypted_password shadow_encrypted_password
end

user_shadow "root" do
  encrypted_password shadow_encrypted_password
end

group_add username do
  groups [
           "adm",
           "audio",
           "cdrom",
           "crontab",
           "dialout",
           "disk",
           "fax",
           "floppy",
           "games",
           "input",
           "kmem",
           "lp",
           "netdev",
           "operator",
           "plugdev",
           "scanner",
           "ssh",
           "staff",
           "sudo",
           "tty",
           "users",
           "video",
           "voice",
         ]
end

authorized_keys Etc.getgrgid.name do
  source "#{Etc.getpwuid.dir}/.ssh/id_rsa.pub"
end

dotfiles_local_repo_path = "#{home_dir}/src/dotfiles.git"
dotfiles_remote_repo_url = "https://github.com/#{username}/dotfiles.git"
dotfiles_git = "git --git-dir=#{dotfiles_local_repo_path} --work-tree=#{home_dir}"

directory dotfiles_local_repo_path do
  user username
  mode "755"
  owner username
  group groupname
end

execute "git init --bare" do
  user username
  cwd dotfiles_local_repo_path
  not_if "#{dotfiles_git} status"
end

execute "#{dotfiles_git} remote add origin #{dotfiles_remote_repo_url}" do
  user username
  cwd home_dir
  not_if <<~EOF
           #{dotfiles_git} remote get-url --all origin \
			| grep -E ^#{Shellwords.shellescape(Regexp.escape(
           dotfiles_remote_repo_url
         ))}\\$
         EOF
end

execute "#{dotfiles_git} fetch origin && #{dotfiles_git} checkout -f origin/master && #{dotfiles_git} branch -f master && #{dotfiles_git} branch --set-upstream-to=origin/master master" do
  user username
  cwd home_dir
  not_if <<~EOF
           #{dotfiles_git} log --decorate=full \
			| head -n 1 \
			| grep -E #{Shellwords.shellescape(Regexp.escape(
           "(HEAD, refs/remotes/origin/master, refs/heads/master)"
         ))}
         EOF
end
