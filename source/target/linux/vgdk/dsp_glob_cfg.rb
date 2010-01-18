module DSPGlobConfig

    def send_dsp_glob_config()
    send_cmd("dimt dsp_glob_config 0 alloc_g 10",/DONE/,2) 
    send_cmd("dimt dsp_glob_config 1 alloc_g 10",/DONE/,2) 
    send_cmd("dimt dsp_glob_config 2 alloc_g 10",/DONE/,2) 
    send_cmd("dimt dsp_glob_config 3 alloc_g 10",/DONE/,2) 
    send_cmd("dimt dsp_glob_config 4 alloc_g 10",/DONE/,2) 
    send_cmd("dimt dsp_glob_config 5 alloc_g 10",/DONE/,2) 
    end
    
end