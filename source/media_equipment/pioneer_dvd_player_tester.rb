require 'pioneer_dvd_player'


class DvdInfo
  attr_reader :telnet_ip, :telnet_port
  
  def initialize
    @telnet_ip = '10.0.0.100'
    @telnet_port = 6001
  end
end

test_dvd = MediaEquipment::PioneerDvdPlayer.new(DvdInfo.new,"/dvd_log.txt")
sleep(20)
puts test_dvd.get_title_number
test_dvd.set_subtitle("english")
test_dvd.go_to_track(5)
sleep(10)
puts test_dvd.get_title_number
test_dvd.step_forward
sleep(20)
test_dvd.stop
test_dvd.disconnect
