require 'video_switch'

class SwitchInfo
  attr_reader :telnet_ip, :telnet_port
  
  def initialize
    @telnet_ip = '10.0.0.101'
    @telnet_port = 23
  end
end
$audio_supported = false
def get_conn(obj,outs,video_in,audio_in)
  puts "video #{outs}: "+(obj.get_output_video_connection(outs) == video_in).to_s
  puts "audio #{outs}: "+(obj.get_output_audio_connection(outs) == audio_in).to_s if $audio_supported
end
def get_mute(obj,outs)
  puts "video mute #{outs}: "+obj.is_output_video_muted(outs).to_s
  puts "audio mute #{outs}: "+obj.is_output_audio_muted(outs).to_s if $audio_supported
end

a = ConnectionEquipment::VideoSwitch.new(SwitchInfo.new,"C:\\switch_log.txt")
puts "testing video_audio connect_all and disconnect all"
a.connect_all_video_audio(7)
get_conn(a,9,7,7)
get_conn(a,1,7,7)
get_conn(a,2,7,7)
get_conn(a,15,7,7)
sleep 3
a.disconnect_all_video_audio
get_conn(a,9,0,0)
get_conn(a,1,0,0)
get_conn(a,2,0,0)
get_conn(a,15,0,0)
puts "testing video connect_all and disconnect all"
a.connect_all_video(8)
get_conn(a,9,8,0)
get_conn(a,1,8,0)
get_conn(a,2,8,0)
get_conn(a,15,8,0)
sleep 3
a.disconnect_all_video
get_conn(a,9,0,0)
get_conn(a,1,0,0)
get_conn(a,2,0,0)
get_conn(a,15,0,0)
puts "testing audio connect_all and disconnect all"
a.connect_all_audio(9) if $audio_supported
get_conn(a,9,0,9)
get_conn(a,1,0,9)
get_conn(a,2,0,9)
get_conn(a,15,0,9)
sleep 3
a.disconnect_all_audio if $audio_supported
get_conn(a,9,0,0)
get_conn(a,1,0,0)
get_conn(a,2,0,0)
get_conn(a,15,0,0)
puts "testing connect video_audio"
a.connect_video_audio(6,["3","8-10","30-32"])
get_conn(a,9,6,6)
get_conn(a,1,0,0)
get_conn(a,2,0,0)
get_conn(a,15,0,0)
puts "testing video connect"
a.connect_video(13, 2)
get_conn(a,2,13,0)
puts "testing audio connect"
a.connect_audio(8, [5,"10-16"]) if $audio_supported
get_conn(a,15,0,10)
puts "testing video_audio disconnect"
a.disconnect_video_audio(["31-32"])
get_conn(a,13,0,0)
puts "testing video disconnect"
a.disconnect_video(8)
get_conn(a,8,0,6)
puts "testing audio disconnect"
a.disconnect_audio(9) if $audio_supported
get_conn(a,9,6,0)
if $audio_supported
	puts "testing audio gains"
	a.set_input_audio_gain(6,-10) 
	puts "audio gain 6: "+(a.get_input_audio_gain(6) == -10).to_s 
	a.set_input_audio_gain(6,0) 
	puts "audio gain 6: "+(a.get_input_audio_gain(6) == 0).to_s 
	a.set_input_audio_gain(6,3) 
	puts "audio gain 6: "+(a.get_input_audio_gain(6) == 3).to_s
	a.reset_all_audio_inputs_levels
	puts "audio gain 6: "+(a.get_input_audio_gain(6) == 0).to_s
	puts "testing output volume"
	a.set_output_volume(14, 64)
	puts "volume 30: "+(a.get_output_volume(14) == 64).to_s
	a.set_output_volume(14, 44)
	puts "volume 30: "+(a.get_output_volume(14) == 44).to_s
	a.set_output_volume(14, 0)
	puts "volume 30: "+(a.get_output_volume(14) == 0).to_s
	a.reset_all_audio_ouput_levels
	puts "volume 30: "+(a.get_output_volume(14) == 64).to_s
	#puts "input frequencies are: "+a.get_input_frequencies(6).to_s
end
puts "testing video mute"
sleep 20
a.mute_video_output(3, true)
get_mute(a,3)
if $audio_supported
	a.mute_audio_output(5, true) 
	get_mute(a,5) if $audio_supported
end
sleep 10
a.mute_video_output(3, false)
get_mute(a,3)
if $audio_supported
	a.mute_audio_output(5, false) 
	get_mute(a,5)
end
sleep 10
puts "testing get mute states"
a.get_outputs_mute_state.sort.each{|key,val| puts "output #{key} is #{val}"}
a.mute_all_audio_ouputs(true) if $audio_supported
a.get_outputs_mute_state.sort.each{|key,val| puts "output #{key} is #{val}"}
a.mute_all_audio_ouputs(false) if $audio_supported
a.get_outputs_mute_state.sort.each{|key,val| puts "output #{key} is #{val}"}
a.mute_all_video_ouputs(true)
a.get_outputs_mute_state.sort.each{|key,val| puts "output #{key} is #{val}"}
a.mute_all_video_ouputs(false)
a.get_outputs_mute_state.sort.each{|key,val| puts "output #{key} is #{val}"}
a.mute_all_video_ouputs(true)
a.mute_all_audio_ouputs(true) if $audio_supported
a.get_outputs_mute_state.sort.each{|key,val| puts "output #{key} is #{val}"}
a.reset_all_mutes
a.get_outputs_mute_state.sort.each{|key,val| puts "output #{key} is #{val}"}
puts "testing front panel lock"
a.lock_front_panel(true)
a.lock_front_panel(false)
puts "testing switch reset"
a.reset_switch
a.disconnect
