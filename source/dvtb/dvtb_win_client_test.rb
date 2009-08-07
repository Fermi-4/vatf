require 'dvtb_win_client'
class TargetInfo
  attr_reader :telnet_ip, :telnet_port
  
  def initialize
    @telnet_ip = '10.218.111.105'
    @telnet_port = 5000
  end
end

client = DvtbHandlers::DvtbWindowsClient.new(TargetInfo.new,"C:/target_log.txt")
#client = DvtbHandlers::DvtbClient.new(TargetInfo.new)

# Example of sending raw commands 
#client.send_cmd("getp vpbe width\n")
#client.send_cmd("getp vpbe height\n")
#client.send_cmd("setp audio samplerate 44100\n")
#client.send_cmd("setp audio seconds 60\n")

# Get Parameters Example
#client.get_param("vpbe width")
client.get_param({"Class" => "vpbe",
                  "Param" => "height"})
#=begin
# Set Parameters Example
client.set_param({"Class" => "vpbe",
                  "Param" => "width",
                  "Value" => "352"})
client.set_param({"Class" => "vpbe",
                  "Param" => "height",
                  "Value" => "240"})
client.set_param({"Class" => "vpbe",
                  "Param" => "xoffset",
                  "Value" => "180"})
client.set_param({"Class" => "vpbe",
                  "Param" => "yoffset",
                  "Value" => "143"})
#=end
client.set_param({"Class" => "viddec",
                  "Param" => "maxFrameRate",
                  "Value" => "30000"})
client.set_param({"Class" => "viddec",
                  "Param" => "maxBitRate",
                  "Value" => "10000000"})
client.set_param({"Class" => "viddec",
                 "Param" =>"forceChromaFormat",
                  "Value" => "4"})
client.set_param({"Class" => "viddec",
                 "Param" =>"displayWidth",
                 "Value" => "0"})
#client.send_cmd("func viddec -s /shreck2\n", "\xA1")
#=end                 
=begin       
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
# Get Parameters Example
#client.get_param("vpbe width")
#client.get_param({"Class" => "vpbe",
#                  "Param" => "height"})


# adding new lines for testing...
# Set Parameters Example
#client.set_param({"Class" => "videnc",
#                  "Param" => "numframes",
#                  "Value" => "300"})
#client.send_cmd("func videnc -t /shreck2\n", "\xA1")
#client.get_param("videnc")
#client.send_cmd("func viddec -s C:/shrek.264\n", "\xA1") if client
#client.wait_for_threads if client
#client.send_cmd("func videnc -t /amara/testing")
#client.set_param({"Class" => "viddec",
#                  "Param" => "-s",
 #                 "Value" => "c:\\shreck1"})
#client.audio_loopback
#sleep 20
#client.print_params_help
client.disconnect 
