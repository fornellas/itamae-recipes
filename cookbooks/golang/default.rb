gopath = "/var/cache/go"
gobin = "/opt/bin"

package 'golang-go'

define(
  :golang_install_bin,
  package: nil,
) do
  bin = params[:name]
  package = params[:package]
  execute "GOPATH=#{gopath} GOBIN=#{gobin} go get #{package} && GOPATH=#{gopath} GOBIN=#{gobin} go install #{package}" do
    user "root"
    not_if "test -e #{gobin}/#{bin}"
  end
end