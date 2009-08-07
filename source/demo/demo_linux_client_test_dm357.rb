require 'demo_linux_client_dm357'
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
    client = DemoHandlers::DemoLinuxClientDM357.new(TargetInfo.new,"C:/target_log.txt")
    client.encode_decode({"time" => '5'})
    client.encode({"video_file" => 'c:\Video_tools\test.264', "time" => '10', "disable_deinterlace" => 'no', "enable_osd" => 'yes'})
    client.encode({"video_file" => 'c:\Video_tools\test.mpeg4', "speech_file" => 'c:\Video_tools\test.g711', "audio_input" => 'line_in', "enable_osd" => 'no', "time" => '2'})
    client.decode({"video_file" => 'c:\Video_tools\akiyo_640x480_420p_300frames_1000000bps.mpeg4'})
    client.decode({"video_file" => 'c:\Video_tools\video_camera_720x480_4000kbps_30fps_900frames_test.264', "speech_file" => 'c:\Video_tools\test1_16bIntel.g711', "enable_osd" => 'no'})

    rescue Exception => e
        puts e.to_s
        raise
    ensure 
        client.disconnect if client
     
end
test




