require File.dirname(__FILE__)+'/dmai_linux_client'

module DmaiHandlers
    class DmaiLinuxClientDM646x < DmaiLinuxClient
        
      def initialize(platform_info, log_path = nil)
        super(platform_info, log_path)  
        @audio_decode1_params['command_name'] = 'audio_decode1_dm6467.x470MV'
        @audio_decode_params['command_name'] = 'audio_decode_io1_dm6467.x470MV'
        @audio_encode1_params['command_name'] = 'audio_encode1_dm6467.x470MV'
        @audio_encode_params['command_name']  = 'audio_encode_io1_dm6467.x470MV'
        
        @video_encode_params['command_name'] = 'video_encode_io1_dm6467.x470MV'
        @video_decode_params['command_name'] = 'video_decode_io2_dm6467.x470MV'
        @video_decode_params['codec'] = {'name' => '-c', 'values' => {'h264' => 'h264dec --semiplanar', 'h264_1080' => 'h2641080p60vdec --semiplanar', 'mpeg4' => 'mpeg4dec', 'mpeg2' => 'mpeg2dec --semiplanar'}}
        
        @speech_decode_params['command_name'] = 'speech_decode_io1_dm6467.x470MV'
        @speech_decode1_params['command_name'] = 'speech_decode1_dm6467.x470MV'
        @speech_encode_params['command_name'] = 'speech_encode_io1_dm6467.x470MV'
        @speech_encode1_params['command_name'] = 'speech_encode1_dm6467.x470MV'
        
        @video_display_params['command_name'] = 'video_display_dm6467.x470MV'
        @video_loopback_copy_params['command_name'] = 'video_loopback_copy_dm6467.x470MV'
        @video_loopback_params['command_name'] = 'video_loopback_dm6467.x470MV'
        @video_loopback_resize_params['command_name'] = 'video_loopback_resize_dm6467.x470MV'
        @video_loopback_convert_params['command_name'] = 'video_loopback_convert_dm6467.x470MV'
        @video_loopback_blend_params['command_name'] = 'video_loopback_blend_dm6467.x470MV'
      end
        
      def video_decode(params)
        super(params)
        tempfile = params['output_file']+'_temp'
        File.rename(params['output_file'], tempfile)
        convert_420sp_to_420p(tempfile, params['output_file'], params['resolution'], params['num_of_frames'].to_i)
        File.delete(tempfile)
      end

    end
end