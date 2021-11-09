gopath = "/opt/go"

package 'golang-go'

define(
  :golang_install_bin,
  package: nil,
) do
	bin = params[:name]
	package = params[:package]
  execute "GOPATH=#{gopath} go get #{package} && GOPATH=#{gopath} go install #{package}" do
  	user "root"
  	not_if "test -e #{gopath}/bin/#{bin}"
  end
end