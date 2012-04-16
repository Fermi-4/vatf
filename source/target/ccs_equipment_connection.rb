require 'timeout'

module BoardController
  class Command
    def get_command(options=nil)
    end
  end
  
  class Ccsv4Command < Command
    def initialize
      super
      @CCS_EXECUTABLE    = ' jre/bin/java -jar startup.jar '
      @LOADTI_EXECUTABLE = 'loadti '
      @DSS_EXECUTABLE = 'dss.bat '
      @ccs_options = {
        'workspace'     => {'name' => '-data',                  'values' => ''},
        'project_name'  => {'name' => '-ccs.name',              'values' => ''},
        'device'        => {'name' => '-ccs.device',            'values' => {'c64x+'  => 'com.ti.ccstudio.deviceModel.C6000.GenericC64xPlusDevice', 'c64x'  => 'com.ti.ccstudio.deviceModel.C6000.GenericC64xPlusDevice'}},
        'location'      => {'name' => '-ccs.location',          'values' => ''},
        'kind'          => {'name' => '-ccs.kind',              'values' => ''},
        'endianness'    => {'name' => '-ccs.endianness',        'values' => ''},
        'cgt_version'   => {'name' => '-ccs.cgtVersion',        'values' => ''},
        'cmd_file'      => {'name' => '-ccs.cmd',               'values' => ''},
        'runtime_lib'   => {'name' => '-ccs.rts',               'values' => ''},
        'asm_only'      => {'name' => '-ccs.asmOnly',           'values' => ''},
        'configurations'=> {'name' => '-ccs.configurations',    'values' => ''},
        'references'    => {'name' => '-ccs.references',        'values' => ''},
        'set_build_opt' => {'name' => '-ccs.setBuildOption',    'values' => ''},
        'add_file'      => {'name' => '-ccs.copyFile',          'values' => ''},
        'link_file'     => {'name' => '-ccs.linkFile',          'values' => ''},
        'define_var'    => {'name' => '-ccs.definePathVariable','values' => ''},
        'overwrite'     => {'name' => '-ccs.overwrite',         'values' => {'yes'=>'full', 'no'=>'keep'}},
        'args'          => {'name' => '-ccs.args',              'values' => ''},
        'enable_bios'   => {'name' => '',                       'values' => {'yes'=>'-rtsc.enableDspBios','no'=>''}},
        'bios_version'  => {'name' => '-rtsc.biosVersion',      'values' => ''},
        'enable_rtsc'   => {'name' => '',                       'values' => {'yes'=>'-rtsc.enableRtsc','no'=>''}},
        'xdc_version'   => {'name' => '-rtsc.xdcVersion',       'values' => ''},
      }
      @loadti_options = {
        'async'         => {'name' => '',     'values' => {'yes'=>'-a', 'no'=>''}},
        'config'        => {'name' => '-c',   'values' => ''},
        'load_only'     => {'name' => '',     'values' => {'yes'=>'-l', 'no'=>''}},
        'mem_load_raw'  => {'name' => '-mlr', 'values' => ''},
        'mem_load_dat'  => {'name' => '-mld', 'values' => ''},
        'mem_save_raw'  => {'name' => '-msr', 'values' => ''},
        'mem_save_dat'  => {'name' => '-msd', 'values' => ''},
        'no_profile'    => {'name' => '',     'values' => {'yes'=>'-n', 'no'=>''}},
        'quiet'         => {'name' => '',     'values' => {'yes'=>'-q', 'no'=>''}},
        'reset'         => {'name' => '',     'values' => {'yes'=>'-r', 'no'=>''}},
        'stdout_file'   =>  {'name' => '-s',  'values' => ''},
        'timeout'       =>  {'name' => '-t',  'values' => ''},
        'xml_log'       => {'name' => '-x',   'values' => ''},
      }
      @dss_options = {}
      
      if OsFunctions::is_linux? 
        @is_linux = true
      else
        @is_linux = false
      end
      
    end
    
    private
    def translate_options(options, dictionary)
      command=''
      if options.kind_of?(Hash) 
        options.each { |key,value| 
          if dictionary[key]
            param_value = (dictionary[key]['values'].kind_of?(Hash) and dictionary[key]['values'].has_key?(value)) ? "#{dictionary[key]['values'][value]}" : value.kind_of?(Array) ? (value.map{|v| v + ' '}).to_s : value 
            command += "#{dictionary[key]['name']} #{param_value} "
          end 
        }
      elsif options.kind_of?(String)
        command = options
      else
        raise "Invalid options specified: #{options.to_s}"
      end
      command
    end
  end
  
  class Ccsv5Command < Ccsv4Command
    def initialize
      super
      if @is_linux
        @CCS_EXECUTABLE    = ' eclipse -noSplash '
        @LOADTI_EXECUTABLE = 'loadti.sh '
        @DSS_EXECUTABLE    = 'dss.sh ' 
      else
        @CCS_EXECUTABLE    = ' eclipsec -noSplash '
        @LOADTI_EXECUTABLE = 'loadti.bat '
        @DSS_EXECUTABLE    = 'dss.bat '
      end
    end
  end
  
  class Ccsv4CreateCommand < Ccsv4Command
    def get_command(options)
      @CCS_EXECUTABLE+'-application com.ti.ccstudio.apps.projectCreate '+translate_options(options, @ccs_options)
    end
  end
  
  class Ccsv4BuildCommand < Ccsv4Command
    def get_command(options)
      @CCS_EXECUTABLE+'-application com.ti.ccstudio.apps.projectBuild -ccs.projects'+" #{options['project_name']} "+translate_options(options, @ccs_options)    
    end
  end
  
  class Ccsv4LoadCommand < Ccsv4Command
    def get_command(options)
      @LOADTI_EXECUTABLE+translate_options(options.merge({'load_only'=>'yes'}), @loadti_options)+" #{options['outfile']} #{options['usr_args']}"
    end
  end
  
  class Ccsv4RunCommand < Ccsv4Command
    def get_command(options)
      @LOADTI_EXECUTABLE+translate_options(options, @loadti_options)+" #{options['outfile']} #{options['usr_args']}"
    end
  end
  
  class Ccsv4RunDssCommand < Ccsv4Command
    def get_command(options)
      @DSS_EXECUTABLE+translate_options(options, @dss_options)+" #{options['script']} #{options['usr_args']}"
    end
  end
  
  class Ccsv5CreateCommand < Ccsv5Command
    def get_command(options)
      @CCS_EXECUTABLE+'-application com.ti.ccstudio.apps.projectCreate '+translate_options(options, @ccs_options)
    end
  end
  
  class Ccsv5BuildCommand < Ccsv5Command
    def get_command(options)
      @CCS_EXECUTABLE+'-application com.ti.ccstudio.apps.projectBuild -ccs.projects'+" #{options['project_name']} "+translate_options(options, @ccs_options)    
    end
  end
  
  class Ccsv5LoadCommand < Ccsv5Command
    def get_command(options)
      @LOADTI_EXECUTABLE+translate_options(options.merge({'load_only'=>'yes'}), @loadti_options)+" #{options['outfile']} #{options['usr_args']}"
    end
  end
  
  class Ccsv5RunCommand < Ccsv5Command
    def get_command(options)
      @LOADTI_EXECUTABLE+translate_options(options, @loadti_options)+" #{options['outfile']} #{options['usr_args']}"
    end
  end
  
  class Ccsv5RunDssCommand < Ccsv5Command
    def get_command(options)
      @DSS_EXECUTABLE+translate_options(options, @dss_options)+" #{options['script']} #{options['usr_args']}"
    end
  end
  
  class CcsController 
    attr_reader :result
    attr_accessor :workspace, :logfp, :jsEnvArgsFile, :tempdir
    #type: The type of commands to use. Only 'Ccsv4' supported for now
    def initialize(params)
      @ccs_type = params['ccs_type'] ? params['ccs_type'] : 'Ccsv5'
      @ccs_type = @ccs_type[0].upcase + @ccs_type[1..-1].downcase
      @workspace   = params['ccs_workspace'] ? params['ccs_workspace'] : '.'
      @INSTALL_DIR = params['ccs_install_dir']
      @result =''
      setenv()
      switch_type(@ccs_type)
    end
    
    def setenv
      if @ccs_type == 'Ccsv4'
        @loadti_dir = "#{@INSTALL_DIR}/../scripting/examples/loadti"
      else
        @loadti_dir = "#{@INSTALL_DIR}/ccs_base/scripting/examples/loadti"
      end
      @dss_dir      = "#{@INSTALL_DIR}/ccs_base/scripting/bin"
    end

=begin       
    def connect
      if OsFunctions::is_linux? 
        return IO.popen("sh", "w+")
      else
        return IO.popen("cmd", "w+")
      end
    end
=end    
    def disconnect
    end
  
    def switch_type(type)
      @create_cmd = BoardController.const_get("#{type}CreateCommand").new
      @build_cmd = BoardController.const_get("#{type}BuildCommand").new
      @load_cmd = BoardController.const_get("#{type}LoadCommand").new
      @run_cmd = BoardController.const_get("#{type}RunCommand").new
      @run_dss_cmd = BoardController.const_get("#{type}RunDssCommand").new
    end
=begin   
    def execute_cmds (cmds, keep_log=false)
      pipe = connect()
      cmds.each {|cmd|
        pipe.puts cmd
      }
      pipe.close_write
      keep_log ? @result = @result + pipe.read : @result = pipe.read
      pipe.close
      puts @result if !keep_log
    end
=end    
    def create(*params)
      timeout = params[0]
      options = params[1]
      send_cmd("#{@INSTALL_DIR}/#{@create_cmd.get_command(options.merge({'workspace' => @workspace}))}", timeout) 
    end
    
    def build(*params)
      timeout = params[0]
      options = params[1]
      send_cmd("#{@INSTALL_DIR}/#{@build_cmd.get_command(options.merge({'workspace' => @workspace}))}", timeout)
    end
    
    def load(*params)
      outfile = params[0]
      timeout = params[1]
      options = params[2]
      extras = params[3..-1]
      args = ''
      extras.each{|v| args = "#{args} #{v}"}
      appendAutotestEnv("#{@loadti_dir}/main.js")
      send_cmd("export AUTO_ENV_ARGS=#{@jsEnvArgsFile}; #{@loadti_dir}/#{@load_cmd.get_command(options.merge({'outfile' => outfile, 'usr_args' => args}))}", timeout)
    end
    
    def run(*params)
      outfile = params[0]
      timeout = params[1]
      options = params[2]
      extras = params[3..-1]
      args = ''
      extras.each{|v| args = "#{args} #{v}"}
      appendAutotestEnv("#{@loadti_dir}/main.js")
      send_cmd("export AUTO_ENV_ARGS=#{@jsEnvArgsFile}; #{@loadti_dir}/#{@run_cmd.get_command(options.merge({'outfile' => outfile, 'usr_args' => args}))}", timeout)  
    end
    
    def run_dss(*params)
      script = params[0]
      timeout = params[1]
      extras = params[2..-1]
      args = ''
      extras.each{|v| args = "#{args} #{v}"}
      auto_file = appendAutotestEnv(script)
      send_cmd("export AUTO_ENV_ARGS=#{@jsEnvArgsFile}; #{@dss_dir}/#{@run_dss_cmd.get_command('')} #{auto_file} #{args}", timeout)  
    end
    
    def build_and_run(*params)
      options = params[0]
      outfile = params[1] 
      args = params[2] ? params[2] : ''
      puts "\n Creating project"
      create(options)
      puts "\n Building project"
      build(options, true)
      puts "\n Running project"
      run(options, outfile, args, true)
      puts @response
    end
    
    def send_cmd(command, timeout=10, expected_match=/.*/)
      begin
        @timeout = false
        Timeout::timeout(timeout) {
          @response = ''
          @logfp.call "Host: \n" + command
          @response = `#{command} 2>&1 | tee #{@tempdir}/response`
          @logfp.call "Target: \n" + @response
        }
        @timeout = @response.match(expected_match) == nil
      rescue Timeout::Error 
        puts "TIMEOUT executing #{command}"
        @timeout = true
        raise 
      end
    end
    
    def send_cmd_nonblock(command, timeout=10, expected_match=/.*/)
      Thread.new(command, timeout, expected_match) do |a,b,c|
        send_cmd(a,b,c)
      end
      sleep 1   # Make sure the new thread starts before returning to calling thread
    end
    
    def response
      x=`cat #{@tempdir}/response`
      x
    end
    
    def timeout?
      @timeout
    end
    
    def update_response(type='default')
      x=`cat #{@tempdir}/response`
      x
    end
    
    # Load javascript with test automation parameters
    def appendAutotestEnv(js_script)
      outfile_name = File.join(File.dirname(js_script), "auto_#{File.basename(js_script)}")
      if !File.exists?(outfile_name)
        out_file = File.new(outfile_name, 'w')
        in_file = File.new(js_script, 'r')
        out_file.puts("load(java.lang.System.getenv(\"AUTO_ENV_ARGS\"));")
        in_file.each do |line|
          out_file.puts line
        end
        in_file.close
        out_file.close
      end
      outfile_name
    end
    
    def send_ipc_data(data, timeout=-1)
      begin
        if timeout > 1
          Timeout::timeout(timeout) {
            `echo #{data} > #{@tempdir}/in`
          }
        else
          `echo #{data} > #{@tempdir}/in`
        end
      rescue Timeout::Error 
        puts "TIMEOUT sending ipc data:#{data}"
        raise 
      end
    end
      
    
    
    def read_ipc_data(timeout=-1)
      begin
        data='' 
        if timeout > 0
          Timeout::timeout(timeout) {
            data = `read line < #{@tempdir}/out; echo $line`
          }
        else
          data = `read line < #{@tempdir}/out; echo $line`
        end
        return data  
      rescue Timeout::Error 
        puts "TIMEOUT receiving ipc data"
        raise
      end
    end

  end
  
end
