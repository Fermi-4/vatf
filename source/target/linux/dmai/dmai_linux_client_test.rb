require 'dmai_linux_client_dm365'
class TargetInfo
  attr_reader :telnet_ip, :telnet_passwd, :telnet_port, :executable_path, :prompt, :telnet_login, :login_prompt, :serial_port
  
  def initialize
    @telnet_ip = '10.0.0.100'
    @telnet_port = 6012
    @executable_path = '/drop2'
    @prompt = /root.*#/
    @telnet_login = 'root'
    @login_prompt = 'login'
    @nfs_root_path = '/usr/workdir/filesys/dvsdk_310/dm365'
    @samba_root_path = "\\\\10.218.111.201\\filesys\\dvsdk_310\\dm365"
  end
end

def test
    client = DmaiHandlers::DmaiLinuxClientDM365.new(TargetInfo.new,"C:/target_log.txt")
    client.video_encode({
      'input_file' => 'C:\\Video_tools\\buildings_320x240_420p_1frames.yuv',
      'output_file' => 'C:\Video_tools\\atest.mpeg4',
      'resolution' => '320x240',
      'codec'      => 'mpeg4'
    })
    rescue Exception => e
        puts e.to_s
        puts e.backtrace.to_s
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

