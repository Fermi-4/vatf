require 'dvtb_linux_client_dm644x'
class TargetInfo
  attr_reader :telnet_ip, :telnet_port, :executable_path, :prompt, :telnet_login, :login_prompt
  
  def initialize
    @telnet_ip = '10.0.0.100'
    @telnet_port = 6004
    @executable_path = '/dvtb'
    @prompt = /#/
    @telnet_login = 'root'
    @login_prompt = 'login'
    @nfs_root_path = '/smb-nfs'
    @samba_root_path = "\\\\10.218.111.207\\smb-nfs"
  end
end

def test
    client = DvtbHandlers::DvtbLinuxClientDM644X.new(TargetInfo.new,"C:/target_log.txt")
    client.connect
    client.get_param({"Class" => "vpbe",
                      "Param" => "imageHeight"})
    client.set_param({"Class" => "vpbe",
                      "Param" => "imageHeight",
                      "Value" => "480"})
    client.set_param({"Class" => "viddec",
                      "Param" => "codec",
                      "Value" => "mpeg4dec"})
=begin
    client.set_param({"Class" => "vpbe",
                      "Param" => "imageWidth",
                      "Value" => "640"})
    client.set_param({"Class" => "viddec",
                      "Param" => "numFrames",
                      "Value" => "300"})
    client.video_decoding({"Source" => 'c:\Video_tools\akiyo_640x480_420p_300frames_1000000bps.mpeg4'})
    client.set_param({"Class" => "vpbe",
                      "Param" => "imageWidth",
                      "Value" => "720"})
    client.set_param({"Class" => "viddec",
                      "Param" => "numFrames",
                      "Value" => "252"})
    client.video_play({"Source" => 'c:\Video_tools\parkrun_720x480_422i_252frames.yuv'})
=end
    client.set_param({"Class" => "vpbe",
                      "Param" => "imageWidth",
                      "Value" => "720"})
    client.set_param({"Class" => "viddec",
                      "Param" => "numFrames",
                      "Value" => "726"})
    client.video_decoding({"Source" => 'c:\Video_tools\D1_monsters_2_720x480_SP_512kbps_10fps_726frames.mpeg4'})
=begin
    client.set_param({"Class" => "viddec",
                      "Param" => "numFrames",
                      "Value" => "30"})
    client.video_decoding({"Source" => 'c:\Video_tools\akiyo_640x480_420p_300frames_1000000bps.mpeg4', 'Target' => 'c:\Video_tools\akiyo_640x480_420p_300frames_1000000bps_test.yuv'})
=end
    rescue Exception => e
        puts e.to_s
        raise
    ensure 
        client.disconnect
     
end
test


=begin
#client.set_param({"Class" => "vpbe",
#                  "Param" => "xoffset",
#                  "Value" => "180"})
#client.set_param({"Class" => "vpbe",
#                  "Param" => "yoffset",
#                  "Value" => "143"})

client.set_param({"Class" => "viddec",
                  "Param" => "maxFrameRate",
                  "Value" => "30000"})
client.set_param({"Class" => "viddec",
                  "Param" => "maxBitRate",
                  "Value" => "1000000"})
client.set_param({"Class" => "viddec",
                 "Param" =>"forceChromaFormat",
                  "Value" => "4"})
client.set_param({"Class" => "viddec",
                 "Param" =>"displayWidth",
                 "Value" => "0"})
                
       
#client.set_param({"Class" => "vpfe",
#                  "Param" => "width",
#                  "Value" => "352"})
#client.set_param({"Class" => "vpfe",
#                  "Param" => "height",
#                  "Value" => "240"})          
client.set_param({"Class" => "videnc",
                  "Param" => "targetBitRate",
                  "Value" => "10000000"})
client.set_param({"Class" => "videnc",
                  "Param" => "maxBitRate",
                  "Value" => "10000000"})
client.set_param({"Class" => "videnc",
                  "Param" => "numframes",
                  "Value" => "250"})
client.set_param({"Class" => "videnc",
                  "Param" => "targetFrameRate",
                  "Value" => "30000"})
client.set_param({"Class" => "videnc",
                  "Param" => "maxFrameRate",
                  "Value" => "30000"})
client.set_param({"Class" => "videnc",
                  "Param" => "encodingPreset",
                  "Value" => "1"})
client.set_param({"Class" => "videnc",
                  "Param" => "rateControlPreset",
                  "Value" => "3"})
client.set_param({"Class" => "videnc",
                  "Param" => "intraFrameInterval",
                  "Value" => "3"})
client.send_cmd("func videnc -t /shreck2\n", "\xA1")                  
=end                 

