# ; Source MAC address for Voice Channel
# ; Note the name of the string is fixed dspMacVoiceSrc prefixes
# ; dsp_core followed by MAC address index. 
require File.dirname(__FILE__)+'/eth_info'
include ETHInfo
module XDPVarSetSrcEVM
def send_xdp_var_set_srm_evm()
    platform_info = Eth_info.new()
    platform_mac = platform_info.get_platform_mac
    platform_ip = platform_info.get_platform_ip
    send_cmd("cc xdp_var set dspMacVoiceSrc0_0 #{platform_mac["CORE_0"]}",/OK/,2)
    send_cmd("cc xdp_var set dspMacVoiceSrc1_0 #{platform_mac["CORE_1"]}",/OK/,2)
    send_cmd("cc xdp_var set dspMacVoiceSrc2_0 #{platform_mac["CORE_2"]}",/OK/,2)
    send_cmd("cc xdp_var set dspMacVoiceSrc3_0 #{platform_mac["CORE_3"]}",/OK/,2)
    send_cmd("cc xdp_var set dspMacVoiceSrc4_0 #{platform_mac["CORE_4"]}",/OK/,2)
    send_cmd("cc xdp_var set dspMacVoiceSrc5_0 #{platform_mac["CORE_5"]}",/OK/,2)

    send_cmd("cc xdp_var set dspIpVoiceSrc0_0 #{platform_ip["CORE_0"]}",/OK/,2)
    send_cmd("cc xdp_var set dspIpVoiceSrc1_0 #{platform_ip["CORE_1"]}",/OK/,2)
    send_cmd("cc xdp_var set dspIpVoiceSrc2_0 #{platform_ip["CORE_2"]}",/OK/,2)
    send_cmd("cc xdp_var set dspIpVoiceSrc3_0 #{platform_ip["CORE_3"]}",/OK/,2)
    send_cmd("cc xdp_var set dspIpVoiceSrc4_0 #{platform_ip["CORE_4"]}",/OK/,2)
    send_cmd("cc xdp_var set dspIpVoiceSrc5_0 #{platform_ip["CORE_5"]}",/OK/,2)

end
end
# ; Blk Memory Configuration 
# ;cc xdp_var set dspMacBlkSrc0 0A:00:28:2E:FE:F4
# ;cc xdp_var set dspIpBlkSrc0  10.218.109.140
# ;cc xdp_var set dspUdpBlkSrc0 0x7802
