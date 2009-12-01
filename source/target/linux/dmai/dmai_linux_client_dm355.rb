require File.dirname(__FILE__)+'/dmai_linux_client'

module DmaiHandlers
    class DmaiLinuxClientDM355 < DmaiLinuxClient
        
        def initialize(platform_info, log_path = nil)
            super(platform_info, log_path)  
            @video_encode_params['command_name'] ='video_encode_io1_dm355.x470MV'
            @video_decode_params['command_name'] ='video_decode_io2_dm355.x470MV'
            @speech_decode_params['command_name'] ='speech_decode_io1_dm355.x470MV'
            @image_encode_params['command_name'] ='image_encode_io1_dm355.x470MV'
            @image_decode_params['command_name'] ='image_decode_io1_dm355.x470MV'
            @video_display_params['command_name'] ='video_display_dm355.x470MV'
            @video_multi_chan_encode_params['command_name'] ='video_encode_io_multich1_dm355.x470MV'
            @video_loopback_params['command_name'] ='video_loopback_resize_dm355.x470MV'
            @video_loopback_resize_params['command_name'] ='video_loopback_resize_dm355.x470MV'
        end  
    end
end