
require 'dvtb_linux_client_dm357'
class TargetInfo
  attr_reader :telnet_ip, :telnet_port, :executable_path, :prompt, :telnet_login, :login_prompt
  
  def initialize
    @telnet_ip = '10.0.0.100'
    @telnet_port = 6004
    @executable_path = '/ch/dm357_06/exec'
    @prompt = /#/
    @login = 'root'
    @login_prompt = 'login'
    @nfs_root_path = '/usr/workdir/filesys/mv_pro5'
    @samba_root_path = "\\\\158.218.102.36\\filesys\\mv_pro5"
  end
end

def test
    client = DvtbHandlers::DvtbLinuxClientDM357.new(TargetInfo.new,"C:/target_log.txt")
        
    client.set_param({"Class" => "videnc",
                      "Param" => "numFrames",
                      "Value" => "100"})
    client.set_param({"Class" => "engine",
                      "Param" => "name",
                      "Value" => "encode"})
    client.set_param({"Class" => "videnc",
                      "Param" => "codec",
                      "Value" => "mpeg4enc"})
    client.set_param({"Class" => "videnc",
                      "Param" => "maxBitRate",
                      "Value" => "8000000"})
    #client.video_encoding({"Target" => 'c:\Video_tools\harry_780x480_420p_300frames_1000000bps_test.mpeg4'})
    client.set_param({"Class" => "videnc",
                      "Param" => "codec",
                      "Value" => "h264enc"})
    client.video_encoding({"Target" => 'c:\Video_tools\atest.264'})
=begin
    client.set_param({"Class" => "videnc",
                      "Param" => "numFrames",
                      "Value" => "115"})
    client.set_param({"Class" => "videnc",
                      "Param" => "inputHeight",
                      "Value" => "240"})
    client.set_param({"Class" => "videnc",
                      "Param" => "inputWidth",
                      "Value" => "352"})
 	client.video_encoding({"Source" => 'c:\Video_tools\flower_352x240_422i_115frames.yuv', "Target" => 'c:\Video_tools\flower_352x240_422i_115frames.mpeg4'})

    client.set_param({"Class" => "viddec",
                      "Param" => "numFrames",
                      "Value" => "300"})
    client.set_param({"Class" => "viddec",
                      "Param" => "codec",
                      "Value" => "mpeg4dec"})
=end
    #client.video_decoding({"Source" => 'c:\Video_tools\akiyo_640x480_420p_300frames_1000000bps.mpeg4', 'Target' => 'c:\Video_tools\akiyo_640x480_420p_300frames_1000000bps_test.yuv'})
    #client.video_decoding({"Source" => 'c:\Video_tools\akiyo_640x480_420p_300frames_1000000bps.mpeg4'})
=begin
    client.set_param({"Class" => "engine",
                      "Param" => "name",
                      "Value" => "decode"})
  
    client.get_param({"Class" => "vpbe",
                      "Param" => "height"})
    client.set_param({"Class" => "vpbe",
                      "Param" => "height",
                      "Value" => "480"})
    client.set_param({"Class" => "viddec",
                      "Param" => "codec",
                      "Value" => "mpeg4dec"})


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

    client.set_param({"Class" => "vpbe",
                      "Param" => "width",
                      "Value" => "720"})
    client.set_param({"Class" => "viddec",
                      "Param" => "numFrames",
                      "Value" => "300"})
    #client.video_decoding({"Source" => 'c:\Video_tools\harry_780x480_420p_300frames_1000000bps_test.mpeg4'})

    
    
=end
    client.wait_for_threads
    rescue Exception => e
        puts e.to_s
        raise
    ensure 
        client.disconnect if client
     
end
test




