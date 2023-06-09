require File.dirname(__FILE__)+'/demo_linux_client'

module DemoHandlers
  class DemoLinuxClientDM357 < DemoHandlers::DemoLinuxClient
      
      def initialize(platform_info, log_path = nil)
          super(platform_info, log_path = nil)
          @encode_params = {
              'command_name'			=> 'encode',
              'speech_file' 			=> {'name' => '-s', 'values' => ''},
              'video_file'			=> {'name' => '-v', 'values' => ''},
              'video_resolution'		=> {'name' => '-r', 'values' => ''},
              'video_bitrate'		 	=> {'name' => '-b', 'values' => ''},
              'video_signal_format'	=> {'name' => '-y', 'values' => {'525' => '1', '625' => '2'}},
              #'display_out'			=> {'name' => '-O', 'values' => {'composite' => 'composite', 'component' => 'component', 'svideo' => 's-video'}},
              'time'					=> {'name' => '-t', 'values' => ''},
              'audio_input'			=> {'name' => '', 'values' => {'line_in' => '-l', 'mic' => ''}},
              'disable_deinterlace'	=> {'name' => '', 'values' => {'yes' => '-d', 'no' => ''}},
              'enable_osd'			=> {'name' => '', 'values' => {'yes' => '-o', 'no' => ''}},
              'enable_keyboard'		=> {'name' => '', 'values' => {'yes' => '-k', 'no' => ''}},
              'enable_remote'			=> {'name' => '', 'values' => {'yes' => '-i', 'no' => ''}},
              'video_input'			=> {'name' => '', 'values' => {'composite' => '', 'svideo' => '-x'}},
          }
          @decode_params = {
              'command_name'			=> 'decode',
              'speech_file'			=> {'name' => '-s', 'values' => ''},
              'video_file'			=> {'name' => '-v', 'values' => ''},
              'video_signal_format'	=> {'name' => '-y', 'values' => {'525' => '1', '625' => '2'}},
              #'display_out'			=> {'name' => '-O', 'values' => {'composite' => 'composite', 'component' => 'component', 'svideo' => 's-video'}},
              'time'					=> {'name' => '-t', 'values' => ''},
              'enable_osd'			=> {'name' => '', 'values' => {'yes' => '-o', 'no' => ''}},
              'loop'					=> {'name' => '', 'values' => {'yes' => '-l', 'no' => ''}},
              'enable_keyboard'		=> {'name' => '', 'values' => {'yes' => '-k', 'no' => ''}},
              'enable_remote'			=> {'name' => '', 'values' => {'yes' => '-i', 'no' => ''}},
          }
          @encode_decode_params = {
              'command_name'			=> 'encodedecode',
              'video_resolution'		=> {'name' => '-r', 'values' => ''},
              'video_bitrate' 		=> {'name' => '-b', 'values' => ''},
              'video_signal_format'	=> {'name' => '-y', 'values' => {'525' => '1', '625' => '2'}},
              #'display_out'			=> {'name' => '-O', 'values' => {'composite' => 'composite', 'component' => 'component', 'svideo' => 's-video'}},
              'time'					=> {'name' => '-t', 'values' => ''},
              'disable_deinterlace'	=> {'name' => '', 'values' => {'yes' => '-d', 'no' => ''}},
              'passthrough'			=> {'name' => '', 'values' => {'yes' => '-p', 'no' => ''}},
              'enable_osd'			=> {'name' => '', 'values' => {'yes' => '-o', 'no' => ''}},
              'enable_keyboard'		=> {'name' => '', 'values' => {'yes' => '-k', 'no' => ''}},
              'enable_remote'			=> {'name' => '', 'values' => {'yes' => '-i', 'no' => ''}},
              'video_input'			=> {'name' => '', 'values' => {'composite' => '', 'svideo' => '-x'}},
          }
      end         
  end
end


      




