require 'tascam_dvd_player'

class DvdInfo
  attr_reader :telnet_ip, :telnet_port
  
  def initialize
    @telnet_ip = '10.0.0.100'
    @telnet_port = 6002
  end
end

test_dvd = MediaEquipment::TascamDvdPlayer.new(DvdInfo.new,"/dvd_log.txt")
test_dvd.get_dvd_status
test_dvd.power(true)
test_dvd.get_dvd_status
test_dvd.play
test_dvd.get_dvd_status
#test_dvd.open_close_dvd
#test_dvd.open_close_dvd
#test_dvd.get_dvd_status
test_dvd.go_to_track(4)
test_dvd.get_dvd_status
test_dvd.power(false)
