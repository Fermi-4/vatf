# -*- coding: ISO-8859-1 -*-
require 'ftools'

class YuvToRGBConverter
  
    
    
    
    def initialize
        @luminance = Array.new
        @diff_red_444 = Array.new
        @diff_blue_444 = Array.new
        @red_values = Array.new
        @green_values = Array.new
        @blue_values = Array.new
    end
    
    def get_pixel(row,column)
        @r[row][column].to_s+":"+@g[row][column].to_s+":"+@b[row][column].to_s
    end
    
    def convert_uyvy422_file(src_file,src_width,src_height)
        clear_arrays
        yuv_422_to_444_converter = Yuv422To444Converter.new
        @yuv_444_hash = yuv_422_to_444_converter.convert_uyvy(src_file,src_width,src_height)
        
         0.upto(src_height-1) do |i|
            @luminance[i] = Array.new
            @diff_red_444[i] = Array.new
            @diff_blue_444[i] = Array.new
            @red_values[i] = Array.new
            @green_values[i] = Array.new
            @blue_values[i] = Array.new
        end
        
        0.upto(@yuv_444_hash['y'].length-1) do |line|
            0.upto(@yuv_444_hash['y'][0].length-1) do |pixel|
                @luminance[line] << (@yuv_444_hash['y'][line][pixel] - 16) * 255 / 219
                @diff_blue_444[line] << (@yuv_444_hash['u'][line][pixel] - 128) * 127 / 112 
                @diff_red_444[line] << (@yuv_444_hash['v'][line][pixel] - 128) * 127 / 112
            end
        end
        
        0.upto(@luminance.length-1) do |line|
            0.upto(@luminance[0].length-1) do |pixel|
                @red_values[line] << clip((@luminance[line][pixel] + 1.402 * @diff_red_444[line][pixel]))   
                @green_values[line] << clip((@luminance[line][pixel] - 0.344 * @diff_blue_444[line][pixel] - 0.714 * @diff_red_444[line][pixel]))
                @blue_values[line] << clip((@luminance[line][pixel] + 1.722 * @diff_blue_444[line][pixel]))
            end
        end
        
        {"r" => @red_values, "g" => @green_values, "b" => @blue_values}      
    end
    
    def get_yuv_vals(x_coordinate,y_coordinate)
        [@yuv_444_hash["y"][x_coordinate][y_coordinate],@yuv_444_hash["u"][x_coordinate][y_coordinate],@yuv_444_hash["v"][x_coordinate][y_coordinate]]
    end
    
    def print_rgb_vals_to_csv(file_name,start_line=nil,start_column=nil,end_line=nil,end_column=nil)
        file = File.open(file_name,"w")
        start_line = 0 if !start_line
        end_line = @red_values.length-1  if !end_line
        start_column = 0  if !start_column
        end_column = @red_values[0].length-1  if !end_column
        
        start_line.upto(end_line) do |line|
            start_column.upto(end_column) do |pixel|
                file.write(@red_values[line][pixel].to_s+":"+@green_values[line][pixel].to_s+":"+@blue_values[line][pixel].to_s+",")
            end
            file.puts
        end
        file.close
    end
    
    private
    def clear_arrays
        @red_values.clear
        @green_values.clear
        @blue_values.clear
        @luminance.clear
        @diff_red_444.clear
        @diff_blue_444.clear
    end
    
    def clip(value)
        result = [value,255].min
        [0,result].max.round
    end
     
end

class Yuv422To444Converter
    
    def initialize
        @luminance = Array.new
        @diff_red_422 = Array.new
        @diff_blue_422 = Array.new
        @diff_red_444 = Array.new
        @diff_blue_444 = Array.new
    end
    
    def convert_uyvy(src_file, src_width, src_height, dst_file=nil,out_format="yuv")
        clear_arrays
        
        0.upto(src_height-1) do |i|
            @luminance[i] = Array.new
            @diff_red_422[i] = Array.new
            @diff_blue_422[i] = Array.new
            @diff_red_444[i] = Array.new
            @diff_blue_444[i] = Array.new
        end
        
        source = File.new(src_file,"rb")
        
        current_line = 0
        current_column = 0
        while !source.eof?
            if current_column == src_width
            	current_line += 1
            	current_column = 0  
            end           
            @diff_blue_422[current_line] << source.read(1).unpack("C")[0]
            @luminance[current_line] << source.read(1).unpack("C")[0]
            @diff_red_422[current_line] << source.read(1).unpack("C")[0]
            @luminance[current_line] << source.read(1).unpack("C")[0]
            current_column += 2
        end
        
        0.upto(@diff_blue_422.length-1) do |j|
            0.upto(@diff_blue_422[j].length-1) do |i|             
                @diff_blue_444[j][i*2] = @diff_blue_422[j][i]
                @diff_red_444[j][i*2] = @diff_red_422[j][i]
        	    @diff_blue_444[j][i*2+1] = clip((9 * (@diff_blue_422[j][i-1] + @diff_blue_422[j][i-1]) - (@diff_blue_422[j][i-2] + @diff_blue_422[j][i-1]) + 8) >> 4)
        	    @diff_red_444[j][i*2+1] = clip((9 * (@diff_red_422[j][i-1] + @diff_red_422[j][i-1]) - (@diff_red_422[j][i-2] + @diff_red_422[j][i-1]) + 8) >> 4)
            end
        end
        
        if dst_file
        	destination = File.new(dst_file,"wb")
        	if out_format == "yuv"
                write_file(destination,@luminance)
                write_file(destination,@diff_blue_444)
                write_file(destination,@diff_red_444) 
            else
                raise out_format+" is not supported"
            end
        end
        
        {"y" => @luminance, "u" => @diff_blue_444, "v" => @diff_red_444}
        
    end
    
    private
    def clear_arrays
        @luminance.clear
        @diff_red_422.clear
        @diff_blue_422.clear
        @diff_red_444.clear
        @diff_blue_444.clear
    end
    
    def clip(value)
        result = [value,255].min
        [0,result].max
    end
    
    def write_file(file_obj,val_matrix)
        val_matrix.each do |line|
            line.each do |pixel|
                file_obj.write([pixel].pack("C"))
            end
        end
    end
end

