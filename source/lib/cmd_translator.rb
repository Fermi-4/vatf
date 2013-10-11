module CmdTranslator
  @dict_uboot = {
    'mmc init' => { '0.0'     => 'mmc init', 
                    '2008.10' => 'mmc init', 
                    '2010.06' => 'mmc rescan 0',
                    '2011.06' => 'mmc rescan'   },
    'printenv' => { '0.0'     => 'printenv', },
    'tftp'     => { '0.0'     => 'tftp', },
    'dhcp'     => { '0.0'     => 'dhcp', },
    'wdt'     => { '0.0' => Hash.new('').merge!({'omap5-evm' => 'omap-wdt.kernelpet=0', })},
    'env default' => { '0.0'  => 'env default -f',
                       '2011.10' => 'env default -a -f',},
    'fdt_board_name' => {'0.0' => '',
                         '2013.10' => Hash.new('').merge!({'am335x-evm' => 'setenv board_name A33515BB','am335x-sk' => 'setenv board_name A335X_SK', 'beaglebone' => 'setenv board_name A335BONE', 'beaglebone-black' => 'setenv board_name A335BNLT', 'omap5-evm' => 'setenv board_name omap5_uevm', 'dra7xx-evm' => 'setenv board_name dra7xx'})},
  }
  
  @dict_ubuntu = {
    'dhcp-server' => { '12.04'     => 'isc-dhcp-server'},
    'dhcp_conf_file' => { '12.04'     => '/etc/dhcp/dhcpd.conf'},
    'dhcp_sever_setup_file' => { '12.04'     => '/etc/default/isc-dhcp-server'},
    'dhcp_service_restart' => { '12.04'     => 'sudo service isc-dhcp-server restart'},
  }

  # place holder for linux cmds vs. version
  @dict_linux = {
    'set_uart_to_gpio_standby' => { 
                    '3.1.0' => 'cmd for 3.1.0',
                    '3.2.0' => Hash.new('echo uart0_rxd.gpio1_10=0x27,rising > standby_gpio_pad_conf').merge!(
                          {'am335x-evm' => 'echo uart0_rxd.gpio1_10=0x27,rising > standby_gpio_pad_conf', 
                           'am180x-evm' => 'am180x cmd'} ),
    },
    'get_uart_to_gpio_standby' => { 
                    '2.6.37' => 'cmd2.6.37',
                    '3.2.0' => Hash.new('cat standby_gpio_pad_conf').merge!(
                          {'am335x-evm'=>'cat standby_gpio_pad_conf', 
                           'am180x-evm' => 'am180x getcmd'} ),
    },

  }
  
  # Android cmd vs. version
  @dict_android = {
    'gallery_movie_cmp' => {  '2.3.4' => 'com.cooliris.media/.MovieView',
                              '4.0.1' => 'com.android.gallery3d/.app.MovieActivity' },
    'launch_alarm_clock' => {  '2.3.4' => 'shell am start -W -a android.intent.action.MAIN -n com.android.deskclock/.AlarmClock',
                              '4.0.1' => 'shell am start -W -a android.intent.action.MAIN -n com.android.deskclock/.AlarmClock',
                              '4.1.1' => 'shell am start -W -a android.intent.action.MAIN -n com.android.deskclock/.AlarmClock',
                              '4.2.2' => 'shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n  com.android.deskclock/.DeskClock'},
                              
    'wifi_settings_enable_wifi' => {  '2.3.4' => ['__directional_pad_up__', '__directional_pad_center__'],
                                      '4.0.1' => ['__directional_pad_down__','__enter__'] },
                                      
    'wifi_connected_ack_info' => {   '2.3.4' => ['WifiStateTracker', /DhcpHandler:\s+DHCP\s+request\s+succeeded/im],
                                     '4.0.1' => ['ConnectivityService',/ConnectivityChange\s+for\s+WIFI:\s+CONNECTED\/CONNECTED/im],
                                     '4.1.2' => ['DhcpInfoInternal', /makeLinkProperties\s*with\s*empty\s*dns2!/im]},
    
    'alarm_select_minute' => { '2.3.4' =>["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_up__",    "__directional_pad_right__","__directional_pad_up__"],
                               '4.0.1' => ["__directional_pad_up__","__enter__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_up__","__directional_pad_up__","__directional_pad_right__","__directional_pad_right__"],
                               '4.2.2' => ["__tab__","__tab__","__tab__","__tab__","__tab__",
"__enter__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__",
"__directional_pad_left__","__directional_pad_left__","__directional_pad_left__",
"__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__",
"__directional_pad_down__","__directional_pad_right__","__enter__","__enter__",
"__directional_pad_down__","__enter__"]
                               },

    'alarm_save_minute' => { '2.3.4' =>["__directional_pad_down__", "__directional_pad_down__", "__directional_pad_left__", "__enter__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__",
"__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_left__", "__enter__"],
                             '4.0.1' => ["__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__","__directional_pad_right__",  "__enter__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_right__", "__enter__"],
                              '4.2.2' => [" "]
                             },
    'disable_setting_stay_awake' => { '2.3.4' =>["__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__enter__"],
                                      '4.0.1' => ["__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__enter__"]
                            },

    'alarm_delete' => { '2.3.4' =>["__enter__",  "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_right__", "__enter__", "__enter__"],
                        '4.0.1' => ["__enter__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_down__", "__directional_pad_right__", "__enter__", "__directional_pad_right__", "__enter__"]
                      },

    'disable_stay_awake' => { '2.3.4' => ["__directional_pad_down__","__directional_pad_down__","__enter__"],
                           '4.0.1' => ["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__"]
                            },
    'disable_stay_awake_on_resume' => { '2.3.4' => ["__directional_pad_down__","__enter__"],
                           '4.0.1' => ["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__"]
                            },
  'select_bluetooth' => { '2.3.4' => ["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__"],
                           '4.0.1' => ["__directional_pad_up__","__directional_pad_up__","__directional_pad_down__","__enter__","__enter__"],
                          '4.1.1' => ["__directional_pad_up__","__directional_pad_up__","__directional_pad_down__","__enter__","__directional_pad_right__","__enter__"],
			  '4.2.2' => ["__directional_pad_down__","__enter__","__directional_pad_up__","__directional_pad_left__","__directional_pad_right__","__directional_pad_up__","__enter__"]
                            },
  'select_bluetooth_setting' => { '2.3.4' => ["__directional_pad_down__","__enter__"],
                           '4.0.1' => ["__directional_pad_down__","__enter__"]
                            },
  'configure_bluetooth' => { '2.3.4' => ["__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__","__enter__"],
                           '4.0.1' => ["__directional_pad_down__","__enter__","__directional_pad_down__","__enter__"]
			    },
  'select_wireless' => { '2.3.4' => ["__directional_pad_down__","__enter__"],
                         '4.0.1' => ["__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__enter__","__enter__"],
                         '4.1.1' => ["__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__directional_pad_up__","__enter__","__directional_pad_right__","__enter__"],
                         '4.2.2' => ["__directional_pad_up__","__directional_pad_up__","__enter__","__directional_pad_up__","__directional_pad_left__","__directional_pad_right__","__directional_pad_up__","__enter__"]
                             },

  'select_wireless_setting' => { '2.3.4' => ["__directional_pad_down__","__enter__"],
                           '4.0.1' => [" "],
			   '4.2.2' => ["__tab__","__tab__","__directional_pad_left__", "__enter__"]
                            },
  'two_step_down' => { '2.3.4' => ["__directional_pad_down__","__directional_pad_down__"],
                           '4.0.1' => ["__directional_pad_down__"]
                            },
 'clear_access' => { '2.3.4' => ["__enter__","__directional_pad_down__","__enter__"],
                     '4.0.1' => ["__enter__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__"],
                     '4.2.2' => ["__directional_pad_down__","__page_up__","__enter__","__directional_pad_down__","__enter__"]
		   },
  'configure_wireless_open' => { '2.3.4' => ["__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__","gtaccess-open","__directional_pad_down__","__directional_pad_down__","__enter__"],
                           '4.0.1' => ["__enter__","__directional_pad_right__","__directional_pad_right__","__enter__","gtaccess-open", "__enter__","__directional_pad_down__","__directional_pad_right__","__enter__"],
                           '4.1.1' => ["__enter__", "__directional_pad_right__", "__directional_pad_right__", "__directional_pad_right__", "__enter__", "gtaccess-open", "__enter__", "__directional_pad_down__", "__directional_pad_right__", "__enter__"],
                           '4.2.2' => ["__enter__","__directional_pad_down__","__page_up__","__directional_pad_up__","__directional_pad_right__","__directional_pad_right__", "__enter__", "gtaccess-open", "__enter__", "__directional_pad_down__", "__directional_pad_right__", "__enter__"]
                            },
  'find_access_open' => { '2.3.4' => ["__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__"],
                          '4.0.1' => ["__enter__","__directional_pad_down__","__directional_pad_down__"],
                          '4.2.2' => ["__enter__","__directional_pad_down__","__page_up__"]
                        },
  'connect_access_open' => { '2.3.4' => ["__enter__","__directional_pad_down__","__directional_pad_left__","__enter__"],
                           '4.0.1' => ["__enter__","__directional_pad_down__","__directional_pad_down__","__directional_pad_right__","__enter__"]
                            },
  'configure_wireless_wpa-psk' => { '2.3.4' => ["__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__directional_pad_down__","__enter__","gtaccess-wpa-psk","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","q1w2e3r4","__directional_pad_down__","__directional_pad_down__","__enter__"],
                           '4.0.1' => ["__enter__", "__directional_pad_right__","__directional_pad_right__","__enter__","gtaccess-wpa-psk","__enter__","__enter__","__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","q1w2e3r4","__enter__","__directional_pad_right__","__enter__"],
                           '4.1.1' => ["__enter__", "__directional_pad_right__", "__directional_pad_right__", "__directional_pad_right__", "__enter__", "gtaccess-wpa-psk", "__enter__", "__enter__", "__directional_pad_down__", "__directional_pad_down__", "__enter__", "__directional_pad_down__", "q1w2e3r4", "__enter__", "__directional_pad_right__", "__enter__"],
                           '4.2.2' => ["__enter__","__directional_pad_down__","__page_up__","__directional_pad_up__","__directional_pad_right__","__directional_pad_right__", "__enter__", "gtaccess-wpa-psk", "__enter__", "__enter__", "__directional_pad_down__", "__directional_pad_down__", "__enter__", "__directional_pad_down__", "q1w2e3r4", "__enter__", "__directional_pad_right__", "__enter__"]
			   },
  'find_access_wpa-psk' => { '2.3.4' => ["__directional_pad_down__","__directional_pad_down__","__enter__","__directional_pad_down__","__directional_pad_down__"],
                             '4.0.1' => ["__directional_pad_down__","__directional_pad_down__"],
                             '4.2.2' => ["__enter__","__directional_pad_down__","__page_up__"]
                           },
'connect_access__wpa-psk' => { '2.3.4' => ["__enter__","q1w2e3r4","__directional_pad_down__","__directional_pad_left__","__enter__"],
                         '4.0.1' => ["__enter__","q1w2e3r4","__enter__","__directional_pad_down__","__directional_pad_right__","__enter__"]
                           },
  'bluetooth_filter' => { '2.3.4' => [" "],
                          '4.0.1' => "BluetoothAdapterStateMachine",
			  '4.2.2' => "BluetoothAdapter"
                        },
'alarm_set_minute'  => { '2.3.4' => ["__directional_pad_up__","__enter__"],
                          '4.0.1' => ["__directional_pad_up__","__enter__"],
                          '4.2.2' => ["__tab__","__tab__","__tab__","__tab__","__enter__"],
                        }
         }

  # user pass params['cmd'] and params['version']
  def self.get_uboot_cmd(params)  
    params.merge!({'dict' => @dict_uboot})
    get_cmd(params)
    
  end

  def self.get_ubuntu_cmd(params)  
    params.merge!({'dict' => @dict_ubuntu})
    get_cmd(params)
    
  end

  def self.get_linux_cmd(params)
    params.merge!({'dict' => @dict_linux})
    get_cmd(params)
  end
  
  def self.get_android_cmd(params)
    params.merge!({'dict' => @dict_android})
    get_cmd(params)
  end

  def self.get_cmd(params)
    version = params['version']
    dict = params['dict']
    cmd = params['cmd']
    platform = params['platform'] if params.key?('platform')
    cmds_hash = dict["#{cmd}"]
    return cmd if cmds_hash == nil
    versions = cmds_hash.keys.sort {|a,b| b <=> a}  # sort by version
    tmp = versions.select {|v| Gem::Version.new(v.dup) <= Gem::Version.new(version)}
    raise "get_cmd: Unable to find the version matching v<= #{version}\n" if tmp.empty?
    return cmds_hash[tmp[0]] if !cmds_hash[tmp[0]].is_a?(Hash)
    return cmds_hash[tmp[0]][platform]
  end

end
