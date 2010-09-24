      
      tester_from_cli  = @tester.downcase
      target_from_db   = @test_params.target.downcase
      platform_from_db = @test_params.platform.downcase
      
      nfs_root_path_temp = @equipment['dut1'].nfs_root_path
      
      if @test_params.instance_variable_defined?(:@nfs)
        fs = @test_params.nfs
        fs.gsub!(/\\/,'/')
        build_id, build_name = /\/([^\/\\]+?)\/([\w\.\-]+?)$/.match("#{fs.strip}").captures
        nfs_root_path_temp 	= File.join(nfs_root_path_temp, "/autofs/#{build_id}")
        puts `mkdir -p  #{nfs_root_path_temp}` 		
        puts `cd #{nfs_root_path_temp}` 		
        puts `tar -xvzf #{build_name}`
      end

      nfs_root_path_temp = "#{@equipment['server1'].telnet_ip}:#{nfs_root_path_temp}"
      nfs_root_path_temp = @test_params.var_nfs  if @test_params.instance_variable_defined?(:@var_nfs)  # Optionally use external nfs server
          
      boot_params = {'power_handler'=> @power_handler,
                     'platform' => platform_from_db,
                     'tester' => tester_from_cli,
                     'target' => target_from_db ,
                     'image_path' => @test_params.kernel,
                     'server' => @equipment['server1'], 
                     'nfs_root' => nfs_root_path_temp
                     }
      boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
      @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
      
      if boot_required?(@old_keys, @new_keys) # call bootscript if required
        if @equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil
          @equipment['dut1'].connect({'type'=>'serial'})
        elsif @equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil
          @equipment['dut1'].connect({'type'=>'serial'})
        else
          raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
        end
          @equipment['dut1'].boot(boot_params) 
      end
