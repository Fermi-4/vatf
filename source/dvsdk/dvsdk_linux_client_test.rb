require File.dirname(__FILE__) + '/dvsdk'

class TargetInfo
  attr_reader :telnet_ip, :telnet_port, :executable_path, :prompt, :telnet_login, :login_prompt, :nfs_root_path, :samba_root_path
  
  def initialize
    @telnet_ip = '10.0.0.100'
    @telnet_port = 6003
    @executable_path = '/ah/dm355/drop18/exec'
    @prompt = /root.*#/
    @login_prompt = 'login'
    @telnet_login = 'root'
    @nfs_root_path = '/usr/workdir/mv_pro5_08/filesys'
    @samba_root_path = "\\\\10.218.111.201\\mv_pro5_08\\filesys"
  end
end

def test
 client = DvsdkClientHandler::DvsdkLinuxClientDM355.new(TargetInfo.new,"C:/target_log.txt")
 client.connect
 client.set_interface('dvtb')   
 client.set_param({"Class" => "videnc1",
                      "Param" => "numFrames",
                      "Value" => "300"})
 client.set_param({"Class" => "engine",
                      "Param" => "name",
                      "Value" => "encode"})
 client.set_param({"Class" => "videnc1",
                      "Param" => "codec",
                      "Value" => "mpeg4enc"})
 client.set_param({"Class" => "videnc1",
                      "Param" => "maxBitRate",
                      "Value" => "8000000"})
 
    client.video_encoding({"Target" => 'c:\Video_tools\harry_780x480_420p_300frames_1000000bps_test.mpeg4', 'threadId' => 'mpeg4enc'})
    client.wait_for_threads

	client.set_param({"Class" => "engine",
                      "Param" => "name",
                      "Value" => "decode"})
  
    client.get_param({"Class" => "vpbe",
                      "Param" => "imageHeight"})
    client.set_param({"Class" => "vpbe",
                      "Param" => "imageHeight",
                      "Value" => "480"})
    client.set_param({"Class" => "viddec2",
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
    client.set_param({"Class" => "viddec2",
                      "Param" => "numFrames",
                      "Value" => "300"})
    client.video_decoding({"Source" => 'c:\Video_tools\harry_780x480_420p_300frames_1000000bps_test.mpeg4', 'threadId' => 'mpeg4dec'})
    client.wait_for_threads
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