require 'rubygems'

class Converter
  @@TOOL_ROOT_DIR     = File.dirname(__FILE__).gsub('/','\\')+'\..\..\Utils\Video_tools'
  def initialize(tool_dir = nil)
    if tool_dir
      @@TOOL_ROOT_DIR = tool_dir
    end
  end
end

class BmpToAviConverter < Converter
  @@TOOL_EXEC_COMMAND = 'EasyBMPtoAVI.exe '
  
  def convert(params)
    if params.kind_of?(Hash)
      string = " -start "+params["start"]+  
               " -end "+params["end"]+ 
               " -framerate "+params["frameRate"]+
               " -output "+params["output"]
    else
      string = params
    end
    command = @@TOOL_ROOT_DIR+"\\"+@@TOOL_EXEC_COMMAND+string
    puts command
    if system(command) == false
      puts "Error executing BMP to AVI conversion. Error Code:"+$?.to_s
    end
    system("del #{params["output"].gsub(File.basename(params["output"]),"").gsub("/","\\")}*.bmp")
  end
end


class YuvToBmpConverter < Converter
  @@TOOL_EXEC_COMMAND = 'YUVTools_2.1.9.exe '
  
  def convert(params)
    if params.kind_of?(Hash)
      if params["inFile"] == nil || params["outFile"] == nil
        raise ArgumentError, "Missing mandatory parameter in YuvToBmpConversion", caller
      end
      string = " -a convert"
      string += " -n "+params["inFile"]
      string += " -N "+params["outFile"] 
      if params["inSamplingFormat"] == nil
        string += " -s yuv420"                    # default sampling format is yuv 4:2:0
      else
        string += " -s "+params["inSamplingFormat"]
      end
      if params["inComponentOrder"] == nil
        string += " -o yuv"                       # default components order is yuv
      else
        string += " -o "+params["inComponentOrder"]
      end
      if params["inFieldFormat"] == nil
        string += " -f progressive"                # default field format is progressive
      else
        string += " -f "+params["inFieldFormat"]
      end
      if params["inPixelFormat"] == nil
        string += " -p planar"                      # default pixel format is planar
      else
        string += " -p "+params["inPixelFormat"]
      end
      if params["inWidth"] == nil
        string += " -w 720"                      # default image width is 720 (D1)
      else
        string += " -w "+params["inWidth"]
      end
      if params["inHeight"] == nil
        string += " -h 480"                      # default image height is 480 (D1)
      else
        string += " -h "+params["inHeight"]
      end
      if params["outSamplingFormat"] == nil
        string += " -S BMP"                      # default ouput sampling format is BMP
      else
        string += " -S "+params["outSamplingFormat"]
      end
      string += " -F "+params["outFieldFormat"] if params["outFieldFormat"] != nil
      string += " -P "+params["outPixelFormat"] if params["outPixelFormat"] != nil
      string += " -e exit"
    else
      string = params
    end
    command = @@TOOL_ROOT_DIR+"\\"+@@TOOL_EXEC_COMMAND+string
    puts command
    if system(command) == false
      puts "Error executing YUV to BMP conversion. Error Code:"+$?.to_s
    end
  end
end

class AviToYuvConverter < Converter
  @@TOOL_EXEC_COMMAND = 'mencoder'
  
  def convert(params)
    if params.kind_of?(Hash)
      exec_params = {'format' => 'i420'}.merge(params) 
      if params["inFile"] == nil || params["outFile"] == nil
        raise ArgumentError, "Missing mandatory parameter in YuvToBmpConversion", caller
      end
      string = " #{exec_params['inFile']} -ovc raw -of rawvideo -vf format=#{exec_params['format']} -o #{exec_params['outFile']}"
    else
      string = params
    end
    command = @@TOOL_ROOT_DIR+"\\"+@@TOOL_EXEC_COMMAND+string
    puts command
    if system(command) == false
      puts "Error executing AVI to YUV conversion. Error Code:"+$?.to_s
    end
  end
end


class PcmToWave
    
    def convert(source_file, dest_file,companding = "ulaw",channels = 1, sampling_rate = 8000, bytes_per_sec = 8000, alignment = 1, bits_per_sample = 8)
        pcm_file = open(source_file,"rb");
        wave_file = File.new(dest_file,"wb")      
        wave_file.write("RIFF")           # RIFF file descriptor header, Part of wave file header
        if get_companding(companding) == 1
        	wave_file.write([File.size(source_file)+36].pack("V"))   # File Size - 8, Part of wave file header
        else
            wave_file.write([File.size(source_file)+50].pack("V"))
        end
        wave_file.write("WAVE")                   # Part of wave file header
        wave_file.write("fmt ")                   # Part of wave file header
        if get_companding(companding) == 1
        	wave_file.write([16].pack("V"))                         # Part of wave file header
        else
        	wave_file.write([18].pack("V"))                         # Part of wave file header
        end
        wave_file.write([get_companding(companding)].pack("v"))                # Type of WAVE format. This is a PCM header
        wave_file.write([channels].pack("v"))                # mono (0x01) or stereo (0x02)
        wave_file.write([sampling_rate].pack("V"))                       # Sample rate
        wave_file.write([bytes_per_sec].pack("V"))                       # Bytes/Second
        wave_file.write([alignment].pack("v"))                # Block alignment
        if get_companding(companding) != 1
        	wave_file.write([bits_per_sample].pack("V"))                          # Bits per sample
        else
            wave_file.write([bits_per_sample].pack("v"))                          # Bits per sample
        end
        if get_companding(companding) != 1
        	wave_file.write("fact")                   # 
       	 	wave_file.write([4].pack("V"))                          # 
        	wave_file.write([File.size(source_file)].pack("V"))     # Data Size. Part of wave file header
        end
        wave_file.write("data")                   # Part of wave file header
        wave_file.write([File.size(source_file)].pack("V"))     # Data Size. Part of wave file header
        wave_file.write(pcm_file.read)
        wave_file.close
        pcm_file.close    
       	rescue Exception => e 
        	raise "Unable to convert file "+source_file+"\\n"+e.to_s
    end
    
    def get_companding(companding_string)
        case companding_string.strip.downcase
        	when "ulaw"
                7
        	when "alaw"
                6
        	when "linear"
                1
            else 
                raise "Unknown companding type "+companding_string
        end 
    end
end

class WaveToPcm
    def convert(src_file,dst_file)
        wav_file = open(src_file,"rb")
        pcm_file = File.new(dst_file,"wb")
        wav_file.read(16)
        if wav_file.read(1).to_i == 16
            wav_file.read(27)
            pcm_file.write(wav_file.read(File.size(wav_file)-44))
        else
            wav_file.read(41)
            pcm_file.write(wav_file.read(File.size(wav_file)-58))
        end
        wav_file.close
        pcm_file.close
    	rescue Exception => e 
    		raise "Unable to convert file "+src_file+"\\n"+e.to_s
    end
end

class Mpeg4ToYuvConverter < Converter
  @@TOOL_EXEC_COMMAND = 'ffmpeg.exe'

  def convert(conv_params)
	params = {'Source' => '', 'Target' => '', 'data_format' => '420p'}.merge(conv_params)
    exec_args = ' -i ' + params['Source'] + ' -pix_fmt '+get_video_data_format(params['data_format'])+' ' + params['Target']
	File.delete(params['Target']) if File.exists?(params['Target'])
    command = @@TOOL_ROOT_DIR + "\\" + @@TOOL_EXEC_COMMAND + exec_args + ' 2>&1'
    puts command
    if system(command) == false
      puts "Error executing MPEG4 to YUV conversion. Error Code:"+$?.to_s
    end
  end
  
  private
  
  def get_video_data_format(chroma_format)
        case(chroma_format)
            when '420p'
	            'yuv420p'
            when '411p'
	            'yuv411p'
            when '422p'
	            'yuv422p'
            when '411i'
	            'YUV411'
            when '422i'
	            #'yuyv422'
				'uyvy422'
            when '422i_10'
	            'YUV422_10'
			when '444p'
				'yuv444p'
			when 'rgb24'
			when 'j444p'
				'yuvj420p'
			when 'j444p'
				'yuvj420p'
			when 'j422p'
				'yuvj422p'
			when '410p'
				'yuv410p'
            else
	            chroma_format.strip.downcase
        end
  end
  
end
