require File.dirname(__FILE__)+'/dmai_linux_client'

module DmaiHandlers
    class DmaiLinuxClientDM365 < DmaiLinuxClient
        
        def initialize(platform_info, log_path = nil)
            super(platform_info, log_path)  
            @video_encode_params['command_name'] ='video_encode_io1_dm365.x470MV'
            @video_decode_params['command_name'] ='video_decode_io2_dm365.x470MV'
            @speech_decode_params['command_name'] ='speech_decode_io1_dm365.x470MV'
            @speech_decode1_params['command_name'] ='speech_decode1_dm365.x470MV'
            @speech_encode_params['command_name'] ='speech_encode_io1_dm365.x470MV'
            @image_encode_params['command_name'] ='image_encode_io1_dm365.x470MV'
            @image_decode_params['command_name'] ='image_decode_io1_dm365.x470MV'
            @video_display_params['command_name'] ='video_display_dm365.x470MV'
            @video_loopback_copy_params['command_name'] ='video_loopback_copy_dm365.x470MV'
            @video_loopback_params['command_name'] ='video_loopback_dm365.x470MV'
            @video_loopback_resize_params['command_name'] ='video_loopback_resize_dm365.x470MV'
        end  
    end
end