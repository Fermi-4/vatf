require 'host_controller'

class HostInfo
  attr_reader :telnet_ip, :telnet_port, :login_prompt, :login, :telnet_passwd 
  
  def initialize(ip='127.0.0.1',port=5000, lgin_prompt = nil, lgin = nil, passwd = nil)
    @telnet_ip = ip
    @telnet_port = port
	@login_prompt = lgin_prompt if lgin_prompt
	@login = lgin if lgin
	@telnet_passwd = passwd if passwd
  end
end

=begin
host = ExternalSystems::HostController.new(HostInfo.new,"C:/ext_host_log.txt")
puts host.send_cmd('dir','>',10)
puts host.send_cmd('dir','aaaaaaaaaaaaa',10)
host.disconnect 
=end

host = ExternalSystems::HostController.new(HostInfo.new('10.218.111.201',23),"C:/ext_host_log.txt")
puts host.send_cmd('ls','\\$',10)
puts host.send_cmd('ls','aaaaaaaaaaaaa',10)
host.disconnect 
