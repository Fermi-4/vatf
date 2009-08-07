require 'net/telnet'
require 'rubygems'
require 'fileutils'
require File.dirname(__FILE__)+'/../../target/lsp_target_controller'
require File.dirname(__FILE__)+'/dvtb_default_client'
gem 'log4r'
require 'log4r'
require 'log4r/outputter/fileoutputter'

module DvtbHandlers
    
    
    class DvtbLinuxClientDM357 < DvtbHandlers::DvtbDefaultClient
        
        def initialize(platform_info, log_path = nil)
            super(platform_info, log_path)
            @active_threads = 0
            @file_ops = Array.new
            @dvtb_class.merge!({
                'jpegdec' 	=> 'imgdec',
                'jpegenc' 	=> 'imgenc',})
            @dvtb_param = {
                'audio' => {
                    'device'		=> 'device',
                    'samplesize'	=> 'samplesize',
                    'samplerate'	=> 'samplerate',
                    'channels'		=> 'channels',
                    'source'		=> 'source'
                },
                'vpfe' => {
                    'device'		=> 'device',
                    'standard'		=> 'standard',
                    'format'		=> 'format',
                    'input'			=> 'input',
                    'width'			=> 'width',
                    'height'		=> 'height'
                },
                'vpbe' => {
                    'device'		=> 'device',
                    'width'			=> 'imageWidth',
                    'height'		=> 'imageHeight',
                    'screenWidth'	=> 'screenWidth',
                    'screenHeight'	=> 'screenHeight'
                },
                'engine' => {
                    'name'		=> 'name',
                    'trace'		=> 'trace',
                },
                'viddec' => {
                    'codec'				=> 'codec',
                    'maxHeight'			=> 'maxHeight',
                    'maxWidth'			=> 'maxWidth',
                    'maxFrameRate'		=> 'maxFrameRate',
                    'maxBitRate'		=> 'maxBitRate',
                    'dataEndianness'	=> 'dataEndianness',
                    'forceChromaFormat'	=> 'forceChromaFormat',
                    'decodeHeader'		=> 'decodeHeader',
                    'displayWidth'		=> 'displayWidth',
                    'frameSkipMode'		=> 'frameSkipMode',
                    'numframes'			=> 'numFrames',
                },
                'videnc' => {
                    'codec'					=> 'codec',
                    'encodingPreset'		=> 'encodingPreset',
                    'rateControlPreset'		=> 'rateControlPreset',
                    'maxHeight'				=> 'maxHeight',
                    'maxWidth'				=> 'maxWidth',
                    'maxFrameRate'			=> 'maxFrameRate',
                    'maxBitRate'			=> 'maxBitRate',
                    'dataEndianness'		=> 'dataEndianness',
                    'maxInterFrameInterval'	=> 'maxInterFrameInterval',
                    'inputChromaFormat'		=> 'inputChromaFormat',
                    'inputContentType'		=> 'inputContentType',
                    'inputHeight'			=> 'inputHeight',
                    'inputWidth'			=> 'inputWidth',
                    'refFrameRate'			=> 'refFrameRate',
                    'targetFrameRate'		=> 'targetFrameRate',
                    'targetBitRate'			=> 'targetBitRate',
                    'intraFrameInterval'	=> 'intraFrameInterval',
                    'generateHeader'		=> 'generateHeader',
                    'captureWidth'			=> 'captureWidth',
                    'forceIFrame'			=> 'forceIFrame',
                    'numframes'				=> 'numFrames',
                },
                'sphdec' => {
                    'codec'			=> 'codec',
                    'compandingLaw'	=> 'compandingLaw',
                    'packingType'	=> 'packingType',
                    'inbufsize'		=> 'inbufsize',
                    'outbufsize'	=> 'outbufsize',
                },
                'sphenc' => {
                    'codec'			=> 'codec',
                    'seconds'		=> 'seconds',
                    'frameSize'		=> 'frameSize',
                    'compandingLaw'	=> 'compandingLaw',
                    'vadSelection'	=> 'vadSelection',
                    'packingType'	=> 'packingType',
                    'inbufsize'		=> 'inbufsize',
                    'outbufsize'	=> 'outbufsize',
                },
                'jpegdec' => {
                    'codec'					=> 'codec',
                    'maxHeight'				=> 'maxHeight',
                    'maxWidth'				=> 'maxWidth',
                    'maxScans'				=> 'maxScans',
                    'dataEndianness'		=> 'dataEndianness',
                    'forceChromaFormat'		=> 'forceChromaFormat',
                    'numAU'					=> 'numAU',
                    'decodeHeader'			=> 'decodeHeader',
                    'displayWidth'			=> 'displayWidth',
                },
                'jpegenc' => {
                    'codec'					=> 'codec',
                    'maxHeight'				=> 'maxHeight',
                    'maxWidth'				=> 'maxWidth',
                    'maxScans'				=> 'maxScans',
                    'dataEndianness'		=> 'dataEndianness',
                    'forceChromaFormat'		=> 'forceChromaFormat',
                    'numAU'					=> 'numAU',
                    'inputChromaFormat'		=> 'inputChromaFormat',
                    'inputHeight'			=> 'inputHeight',
                    'inputWidth'			=> 'inputWidth',
                    'captureWidth'			=> 'captureWidth',
                    'generateHeader'		=> 'generateHeader',
                    'qValue'				=> 'qValue',
                },
            }
            connect
        end
        
        def translate_value(params)
            case params['Class']
                when 'audio': 
                    case params['Param']
                    when 'device' : '/dev/dsp'
                    else params['Value']
                    end
                when 'vpfe': 
                    case params['Param']
                    when 'device' : '/dev/v4l/video0'
                    when 'standard' : params['Value'].to_s.include?('625') ? '2' : '0'
                    else params['Value']
                    end
                when 'vpbe': 
                    case params['Param']
                    when 'device' : '/dev/fb/3'
                    else params['Value']
                    end
                when 'engine': 
                    case params['Param']
                    when 'name' : params['Value'] == 'encdec'? 'loopback' :  params['Value']
                    else params['Value']
                    end     
                when /vid[end]+c/   
                    case params['Param']
                    when /ChromaFormat/ : params['Value'].to_s.include?('p') ? '1' : '4'
                    else params['Value']
                    end  
                when /jpeg[end]+c/   
                    case params['Param']
                    when /ChromaFormat/ : params['Value'].to_s.include?('p') ? '2' : '4'
                    else params['Value']
                    end  
                when 'sphdec': 
                    case params['Param']
                    when 'numframes' : (params['Value'].to_i/8).to_s
                    else params['Value']
                    end
        	    else params['Value']
            end 
        end
        
        def connect
            send_cmd("cd #{@executable_path}",@prompt)
            send_cmd("./dvtb_loadmodules.sh", @prompt) 	
            send_cmd("./dvtb-r",/$/)
        end
    
        def disconnect
            send_cmd("exit",@prompt)
            super
        end

        def send_cmd(command, expected_match=/.*/, timeout=10)
            @is_timeout = false
            listener = DvtbListener.new(command, expected_match)
            add_listener(listener)
            super(command)
            status = Timeout::timeout(timeout) {
                while (!listener.match) 
                    sleep 0.5
                end
            }
            rescue Timeout::Error => e
            	log_error("On command: "+command.to_s+" waiting for "+expected_match.to_s+" >>> error: "+e.to_s)
            	@is_timeout = true
        	ensure
            	remove_listener(listener)
      	end
      	
        def wait_for_threads(timeout=180)
            puts "\n---> Wait for threads is going to wait #{timeout} seconds\n"
            status = Timeout::timeout(timeout) {
                while (@active_threads!=0) do
                    #puts "Waiting for threads. #{@active_threads} active threads"
                    sleep 5
                end
            }
            rescue Timeout::Error => e
        		log_error("Timeout waiting for Threads to complete")
        		raise
        end

        def set_max_number_of_sockets(video_num_sockets,audio_num_sockets,params=nil)
            # TODO
        end
        
        # DVTB-Server-Dependant Methods
  
        def get_param(params)
            if params.kind_of?(Hash) && @dvtb_class.has_key?(params['Class']) &&  @dvtb_param[params['Class']].has_key?(params['Param'])
    		    string = @dvtb_class[params['Class']]+' '+@dvtb_param[params['Class']][params['Param']].to_s  
            elsif params.kind_of?(String)
            	string = params
            else
                log_warning("#{params['Param']} Parameter on #{params['Class']} Class is Not Supported on this release")
                return 0
            end
            #send_cmd("getp "+string, /PASS:\s*getp/m,1)
            send_cmd("getp "+string)
        end

        def set_param(params)
            if params.kind_of?(Hash) && @dvtb_class.has_key?(params['Class']) &&  @dvtb_param[params['Class']].has_key?(params['Param'])
            	string = @dvtb_class[params['Class']]+' '+@dvtb_param[params['Class']][params['Param']].to_s+' '+translate_value(params)   
            elsif params.kind_of?(String)
            	string = params
            else
                log_warning("#{params['Param']} Parameter on #{params['Class']} Class is Not Supported on this release")
                return 0
            end
			send_cmd("setp "+string, /PASS:\s*setp/m,10)
			#send_cmd("setp "+string)
        end

        def video_decoding(params)
			exec_func(params.merge({"function" => "viddec", "loc_source" => 'dec_source_file.dat', "loc_target" => 'dec_target_file.dat'}))
        end
    
        def video_encoding(params)
			exec_func(params.merge({"function" => "videnc", "loc_source" => 'enc_source_file.dat', "loc_target" => 'enc_target_file.dat'}))
        end
        
        def video_encoding_decoding(params)
            temp_file = 'temp'+get_file_ext(params["threadIdEnc"])
            p_enc = {}.merge!(params); p_enc.delete("Target") ; p_enc['TempTarget'] = temp_file ; p_enc["threadId"] = params["threadIdEnc"]
            p_dec = {}.merge!(params); p_dec.delete("Source") ; p_dec['TempSource'] = temp_file ; p_dec["threadId"] = params["threadIdDec"]
            exec_func(p_enc.merge({"function" => "videnc", "loc_source" => 'enc_source_file.dat', "loc_target" => temp_file}))
          	wait_for_threads
          	exec_func(p_dec.merge({"function" => "viddec", "loc_source" => temp_file, "loc_target" => 'dec_target_file.dat'}))
        end

        def speech_decoding(params)
          	exec_func(params.merge({"function" => "sphdec", "loc_source" => 'dec_source_sph_file.dat', "loc_target" => 'dec_target_sph_file.dat'}))
        end
    
        def speech_encoding(params)
          	exec_func(params.merge({"function" => "sphenc", "loc_source" => 'enc_source_sph_file.dat', "loc_target" => 'enc_target_sph_file.dat'}))
        end
	
        def image_decoding(params)
            exec_func(params.merge({"function" => "imgdec", "loc_source" => 'dec_source_img_file.dat', "loc_target" => 'dec_target_img_file.dat'}))
        end

        def image_encoding(params)
            exec_func(params.merge({"function" => "imgenc", "loc_source" => 'enc_source_img_file.dat', "loc_target" => 'enc_target_img_file.dat'}))
        end
		   
        def video_capture(params)
            exec_func(params.merge({"function" => "videnc", "cmd_tail" => '--nodsp'}))
        end
	
        def video_play(params)
            exec_func(params.merge({"function" => "viddec", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_video.dat'}))
        end
        
        def speech_capture(params)
            exec_func(params.merge({"function" => "sphenc", "cmd_tail" => '--nodsp'}))
        end

        def speech_play(params)
            exec_func(params.merge({"function" => "sphdec", "cmd_tail" => '--nodsp', 'loc_source' => 'raw_speech.dat'}))
        end
                
        private
      
        def exec_func(params)
            time_to_wait = params.has_key?("timeout")? params["timeout"].to_i : 180  
            command = "func "+params["function"]
            FileUtils.cp(params['Source'], "#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\#{params['loc_source']}") if params["Source"]
            command += " -s #{@executable_path}/#{params['loc_source']}" if (params["Source"] || params["TempSource"])
            command += " -t #{@executable_path}/#{params['loc_target']}" if (params["Target"] || params["TempTarget"])
        	command += ' ' + params['cmd_tail'] if params['cmd_tail']	
            threadId = params.has_key?("threadId") ? params["threadId"] : '.+'
            t = Thread.new {
                Thread.critical = true
                @active_threads += 1
                puts "\n\n*********** Started new thread for #{command}"
                Thread.critical = false
                send_cmd(command,/<#{threadId}>\s*[cC]losed/m,time_to_wait)
                sleep 5
                if params["Target"] 
                    FileUtils.cp("#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\#{params['loc_target']}", params["Target"])
                    FileUtils.rm("#{@samba_root_path}#{@executable_path.gsub(/\//,'\\')}\\#{params['loc_target']}")
                end
                Thread.critical = true
                @active_threads -= 1
                puts "\n\n*********** Thread for #{command} completed"
                Thread.critical = false
            }		
        end  
        
        def get_file_ext(threadId)
            case threadId
            when /264/ : '.264'
            else '.mpeg4'
            end
        end
    end
end


      




