class BuildClient
    @@is_config_step_required = false
    
    def initialize
        
    end
    
    # Copy a file from src to dst only if the file doesn't exist in dst or it has been modified in src
    # Both src and dst must be the fullpath to source and destination location respectively
    def self.copy(src,dst)
      if !File.exist?(dst) || (File.mtime(src) > File.mtime(dst))
        #FileUtils.mkdir_p File.dirname(dst), :mode => 0777 if !File.exist?(File.dirname(dst))
        FileUtils.mkdir_p File.dirname(dst) if !File.exist?(File.dirname(dst))
        File.chmod 0777, dst if File.exist?(dst)
        return true if FileUtils.cp(src,dst,:preserve=>true, :verbose=>true)
      end
    end
    
    def self.enable_config_step
      @@is_config_step_required = true
    end
      
    # server is LinuxEquipmentDriver instance connected to Linux Server
    def self.lsp_compile(params)
      directory = params['target_code_dir']
      kernel_inc = params['code_source'] ? params['code_source'].to_s+'/include' : "/view/#{params['target'].downcase}_#{params['platform'].downcase}_#{params['microType'].downcase}/vobs/#{LspConstants::Kernel_Root_Path}/include"
      params['server'].send_cmd("cd #{directory}", params['server'].prompt, 10)
      params['server'].send_cmd("mkdir -m 777 bin", params['server'].prompt, 10) if !File.exists?("#{directory}/bin")
      params['server'].send_cmd("cleartool startview #{params['target'].downcase}_#{params['platform'].downcase}_#{params['microType'].downcase}", params['server'].prompt, 60) if !params['code_source']
      params['server'].send_cmd("make" +
                                " KERNEL_INC=#{kernel_inc}" +
                                " PLATFORM_NAME=#{params['platform'].upcase}" +
                                " TARGET_RELEASE=#{params['target'].upcase}" +
                                " APP_HOME=#{directory}", params['server'].prompt, 1200)
      params['server'].send_cmd("echo waiting for make to finish", params['server'].prompt, 1200)
    end
    
    def self.lsp_configure(params)
      return if !@@is_config_step_required
      directory = params['target_code_dir']
      params['server'].send_cmd("cd #{directory}", params['server'].prompt, 10)
      params['server'].send_cmd("mkdir -m 777 bin", params['server'].prompt, 10) if !File.exists?("#{directory}/bin")
      params['server'].send_cmd("./configure " +
                                " exec_prefix=#{directory}", params['server'].prompt, 1200)
      @@is_config_step_required = false
    end
    
    def self.lsp_make_clean(params)
      directory = params['target_code_dir']
      kernel_inc = params['code_source'] ? params['code_source'].to_s+'/include' : "/view/#{params['target'].downcase}_#{params['platform'].downcase}_#{params['microType'].downcase}/vobs/#{LspConstants::Kernel_Root_Path}/include"
      params['server'].send_cmd("cd #{directory}", params['server'].prompt, 10)
      params['server'].send_cmd("make clean" +
                                " KERNEL_INC=#{kernel_inc}" +
                                " PLATFORM_NAME=#{params['platform'].upcase}" +
                                " TARGET_RELEASE=#{params['target'].upcase}" +
                                " APP_HOME=#{directory}", params['server'].prompt, 120)      
      params['server'].send_cmd("echo waiting for make to finish", params['server'].prompt, 1200)
    end
    
    def self.dir_search(dir, files_array)
      Dir.foreach(dir) {|f|
        if File.directory?(dir+"\\"+f) && !/\.+$/.match(f)
            self.dir_search(dir+"\\"+f, files_array)
        else
            files_array << dir+"\\"+f if !File.directory?(dir+"\\"+f)
        end
	}
	files_array
  end

end
