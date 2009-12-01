
module TestAreas

  RtpInfo = Struct.new(:path)
			 
	def get_matrices(dir_path, result_dir, area, regex = /\.mdb$/)
		result = []
		current_dir = Dir.new(dir_path+'/')
		current_dir.each do |dir_file|
		  if dir_file.match(regex)
		    base_rtp_path = dir_path+'/'+dir_file
        FileUtils.mkdir_p(result_dir)
		    test_rtp_path = result_dir+"/#{area}_"+dir_file 
        puts ">>>>>starting copy at #{Time.now} -- #{dir_file}"
        FileUtils.cp(base_rtp_path,test_rtp_path)
        puts ">>>>>end copy at #{Time.now} -- #{dir_file}"
        File.chmod(755,test_rtp_path)
        result << test_rtp_path
		  end
		end
		result
	end

	def get_rtps(rtp_val, source_dir = '/', result_dir = '/', platform = nil)
	  rtps = []
	  rtp_val.each do |level, areas|
      if areas['test_areas'].kind_of?(String)
        rtps << RtpInfo.new(areas['test_areas'])
      else
        if areas['test_areas'][0].to_s.strip.downcase == 'all'
          src_dir = source_dir.sub(/(\\|\/)$/,'')+'/'+level
          base_dir = Dir.new(src_dir)
          base_dir.each do |current_area|
            current_dir = src_dir+'/'+current_area
            next if !File.directory?(current_dir)
            get_matrices(current_dir,result_dir, level+'_'+current_area).each{|rtp| rtps << RtpInfo.new(rtp)}
            get_matrices(current_dir+'/'+platform,result_dir, platform+'_'+level+'_'+current_area).each{|rtp| rtps << RtpInfo.new(rtp)} if platform && File.exists?(current_dir.sub(/(\\|\/)$/,'')+'/'+platform)
          end
        else
          areas['test_areas'].each do |current_area|
              current_dir = source_dir.sub(/(\\|\/)$/,'')+'/'+level+'/'+current_area
            raise "No test matrices repository defined for #{level} and #{current_area}" if !File.exists?(current_dir) 
            get_matrices(current_dir,result_dir, level+'_'+current_area).each{|rtp| rtps << RtpInfo.new(rtp)}
            get_matrices(current_dir+'/'+platform,result_dir, platform+'_'+level+'_'+current_area).each{|rtp| rtps << RtpInfo.new(rtp)} if platform && File.exists?(current_dir+'/'+platform)
          end
        end
      end
	  end
	  rtps
	end
	
end
