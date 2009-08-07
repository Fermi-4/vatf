class BuildClient
    @@is_config_step_required = false
    
    def initialize
        
    end
    
    # Copy a file from src to dst only if the file doesn't exist in dst or it has been modified in src
    # Both src and dst must be the fullpath to source and destination location respectively
    def self.copy(src,dst)
        if !File.exist?(dst) || (File.mtime(src) > File.mtime(dst))
            FileUtils.mkdir_p(File.dirname(dst)) if !File.exist?(File.dirname(dst))
            File.chmod 0755, dst if File.exist?(dst)
            return true if File.copy(src,dst)
        end
    end
    
    def self.enable_config_step
      @@is_config_step_required = true
    end
      
    # server is LspTargetController instance connected to Linux Server
    def self.lsp_compile(params)
        directory = "#{params['server'].nfs_root_path}/#{params['tester']}/#{params['target']}/#{params['platform']}/#{params['source']}"
        kernel_inc = params['code_source'] ? params['code_source'].to_s+'/include' : "/view/#{params['target'].downcase}_#{params['platform'].downcase}_#{params['microType'].downcase}/vobs/#{LspConstants::Kernel_Root_Path}/include"
        params['server'].send_cmd("cd #{directory}", params['server'].prompt, 10)
        params['server'].send_cmd("mkdir bin", params['server'].prompt, 10) if !File.exists?("#{directory}/bin")
        params['server'].send_cmd("cleartool startview #{params['target'].downcase}_#{params['platform'].downcase}_#{params['microType'].downcase}", params['server'].prompt, 60) if !params['code_source']
        params['server'].send_cmd("make" +
                                  " KERNEL_INC=#{kernel_inc}" +
                                  " PLATFORM_NAME=#{params['platform'].upcase}" +
                                  " TARGET_RELEASE=#{params['target'].upcase}" +
                                  " APP_HOME=#{directory}", params['server'].prompt, 1200)
    end
    
    def self.lsp_configure(params)
        return if !@@is_config_step_required
        directory = "#{params['server'].nfs_root_path}/#{params['tester']}/#{params['target']}/#{params['platform']}/#{params['source']}"
        params['server'].send_cmd("cd #{directory}", params['server'].prompt, 10)
        params['server'].send_cmd("mkdir bin", params['server'].prompt, 10) if !File.exists?("#{directory}/bin")
        params['server'].send_cmd("./configure " +
                                  " exec_prefix=#{directory}", params['server'].prompt, 1200)
        @@is_config_step_required = false
    end
    
    def self.lsp_make_clean(params)
        directory = "#{params['server'].nfs_root_path}/#{params['tester']}/#{params['target']}/#{params['platform']}/#{params['source']}"
        kernel_inc = params['code_source'] ? params['code_source'].to_s+'/include' : "/view/#{params['target'].downcase}_#{params['platform'].downcase}_#{params['microType'].downcase}/vobs/#{LspConstants::Kernel_Root_Path}/include"
        params['server'].send_cmd("cd #{directory}", params['server'].prompt, 10)
        params['server'].send_cmd("make clean" +
                                  " KERNEL_INC=#{kernel_inc}" +
                                  " PLATFORM_NAME=#{params['platform'].upcase}" +
                                  " TARGET_RELEASE=#{params['target'].upcase}" +
                                  " APP_HOME=#{directory}", params['server'].prompt, 120)      
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
