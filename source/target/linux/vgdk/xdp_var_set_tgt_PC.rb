# --------------------------------------------------
# Configuration of video calls
# Remote party address configuration
# Transcoding path is between the PC to Tomahawk gateway to PC
# Tomahawk channels should be configured with PC as remote/destination gw
# Note the name of the string is fixed "dspMacVoiceTgt" prefixes
# dsp_core followed by MAC address index. 
# --------------------------------------------------
require File.dirname(__FILE__)+'/eth_info'
include ETHInfo
module XDPVarSetTgtPC

def send_xdp_var_set_tgt_pc()
# Destination MAC of PC
platform_info = Eth_info.new()
pc_mac = platform_info.get_pc_mac
pc_ip = platform_info.get_pc_ip
send_cmd("cc xdp_var set dspMacVoiceTgt0_0 #{pc_mac}",/OK/,2) 
send_cmd("cc xdp_var set dspMacVoiceTgt1_0 #{pc_mac}",/OK/,2) 
send_cmd("cc xdp_var set dspMacVoiceTgt2_0 #{pc_mac}",/OK/,2)  
send_cmd("cc xdp_var set dspMacVoiceTgt3_0 #{pc_mac}",/OK/,2)  
send_cmd("cc xdp_var set dspMacVoiceTgt4_0 #{pc_mac}",/OK/,2) 
send_cmd("cc xdp_var set dspMacVoiceTgt5_0 #{pc_mac}",/OK/,2) 

# Destination IP of PC
send_cmd("cc xdp_var set dspIpVoiceTgt0_0 #{pc_ip}",/OK/,2)
send_cmd("cc xdp_var set dspIpVoiceTgt1_0 #{pc_ip}",/OK/,2)
send_cmd("cc xdp_var set dspIpVoiceTgt2_0 #{pc_ip}",/OK/,2)
send_cmd("cc xdp_var set dspIpVoiceTgt3_0 #{pc_ip}",/OK/,2)
send_cmd("cc xdp_var set dspIpVoiceTgt4_0 #{pc_ip}",/OK/,2)
send_cmd("cc xdp_var set dspIpVoiceTgt5_0 #{pc_ip}",/OK/,2)


end
end