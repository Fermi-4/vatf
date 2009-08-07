require 'dvtb_dll_client'

class TargetInfo
  attr_reader :telnet_ip, :telnet_port
  
  def initialize
    @telnet_ip = '10.218.111.108'
    @telnet_port = 5000
  end
end

client = DvtbHandlers::DvtbDllClient.new(TargetInfo.new,"C:/target_log.txt")
client.set_max_number_of_sockets(4,0)
client.get_param({"Class" => "vpbe",
                  "Param" => "width"})
                  
client.get_param({"Class" => "vpbe",
                  "Param" => "height"})
# Set Parameters Example
client.set_param({"Class" => "vpbe",
                  "Param" => "width",
                  "Value" => "320"})
client.set_param({"Class" => "vpbe",
                  "Param" => "height",
                  "Value" => "240"})

client.set_param({"Class" => "viddec",
                  "Param" => "maxFrameRate",
                  "Value" => "30000"})
client.set_param({"Class" => "viddec",
                  "Param" => "maxBitRate",
                  "Value" => "10000000"})
client.set_param({"Class" => "viddec",
                 "Param" =>"forceChromaFormat",
                  "Value" => "1"})
client.set_param({"Class" => "viddec",
                 "Param" =>"displayWidth",
                 "Value" => "0"})
client.set_param({"Class" => "viddec",
                 "Param" =>"codec",
                 "Value" => "mpeg4dec"})

client.video_decoding({"Source"=>"C:/Video_tools/cablenews_320x240_420p_511frames_test.mpeg4"}) 
client.video_decoding({"Source"=>"C:/Video_tools/cablenews_320x240_420p_511frames_test.mpeg4", "Target" => "C:/Video_tools/cablenews_320x240_420p_511frames_test.yuv"})            
client.wait_for_threads
client.disconnect 
