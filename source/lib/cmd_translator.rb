module CmdTranslator
  @dict_uboot = {
    'mmc init' => { '0.0'     => 'mmc init', 
                    '2008.10' => 'mmc init', 
                    '2010.06' => 'mmc rescan 0',
                    '2011.06' => 'mmc rescan'   }
  }
  
  # place holder for linux cmds vs. version
  @dict_linux = {
    'testcmd' => {  '0.0' => 'cmd0.0',
                    '2.6.37' => 'cmd2.6.37',
                    '3.1.0'  => 'cmd3.1.0'  }
  }

  # user pass params['cmd'] and params['version']
  def self.get_uboot_cmd(params)  
    params.merge!({'dict' => @dict_uboot})
    get_cmd(params)
    
  end

  def self.get_linux_cmd(params)
    params.merge!({'dict' => @dict_linux})
    get_cmd(params)
  end

  def self.get_cmd(params)
    version = params['version']
    dict = params['dict']
    cmd = params['cmd']
 
    cmds_hash = dict["#{cmd}"]
    versions = cmds_hash.keys.sort {|a,b| b <=> a}  # sort by version
    #tmp = versions.select {|v| v <= version}
    tmp = versions.select {|v| Gem::Version.new(v) <= Gem::Version.new(version)}
    raise "get_cmd: Unable to find the version matching v<= #{version}\n" if tmp.empty?
    return cmds_hash[tmp[0]] 
  end

end
