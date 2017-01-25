module CmdTranslator
  @dict_bmc = {
    'uart_bootmode' => { '0.0' => Hash.new("bootmode #4\n\r").merge!({'k2g-evm' => "bootmode #15\n\r"}),
                         '0.5.0.0' => Hash.new("bootmode #4\n\r").merge!({'k2g-evm' => "bootmode #8\n\r"}),},
    'nand_bootmode' => { '0.0' => Hash.new("bootmode #0\n\r").merge!({'k2g-evm' => "bootmode #11\n\r"})},
    'spi_bootmode' => { '0.0' => Hash.new("bootmode #2\n\r").merge!({'k2g-evm' => "bootmode #5\n\r"})},
    'qspi_bootmode' => { '0.0' => Hash.new("").merge!({'k2g-evm' => "bootmode #9\n\r"})},
    'dsp_no_bootmode' => { '0.0' => Hash.new("bootmode #1\n\r").merge!({'k2l-evm' => "bootmode #15\n\r"})},
    'version' => { '0.0' => Hash.new("ver\n\r")},
    'reboot'        => { '0.0' => "reboot\n\r"},
  }

  @dict_uboot = {
    'mmc init' => { '0.0'     => 'mmc init', 
                    '2008.10' => 'mmc init', 
                    '2010.06' => 'mmc rescan 0',
                    '2011.06' => 'mmc rescan'   },
    'spi_sf_probe' => { '0.0' => Hash.new('sf probe'),},
    'qspi_sf_probe' => { '0.0' => Hash.new('sf probe').merge!({'k2g-evm' => 'sf probe 4:0'}),},
    'printenv' => { '0.0'     => 'printenv', },
    'tftp'     => { '0.0'     => 'tftp', },
    'dhcp'     => { '0.0'     => 'dhcp', },
    'wdt'     => { '0.0' => Hash.new('').merge!({'omap5-evm' => 'omap-wdt.kernelpet=0', 'dra7xx-evm' => 'omap-wdt.kernelpet=0'})},
    'spi'     => { '0.0' => Hash.new('').merge!({'am43xx-epos' => 'spi-ti-qspi.enable_qspi=1'})},
    'env default' => { '0.0'  => 'env default -f',
                       '2011.10' => 'env default -a -f',},
    'run_pmmc' => {'0.0' => 'run run_pmmc', },
    'ramfs_bootargs' => {'0.0' => Hash.new("setenv bootargs ''${bootargs}' root=/dev/ram0 rw '").merge!({'k2g-evm' => 'run args_ramfs'})},
    'k2_sec_bm_install' => {'0.0' => "setenv sec_bm_install 'go ${addr_mon}4 0xc084000 ${mon_size}; mon_install ${addr_mon_mkimg}'", },
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
                    '4.0' => Hash.new(''),
    },
    'get_uart_to_gpio_standby' => { 
                    '2.6.37' => 'cmd2.6.37',
                    '3.2.0' => Hash.new('cat standby_gpio_pad_conf').merge!(
                          {'am335x-evm'=>'cat standby_gpio_pad_conf', 
                           'am180x-evm' => 'am180x getcmd'} ),
                    '4.0' => Hash.new(''),
    },
    'enable_uart_wakeup' => { 
                    '0.0' => Hash.new('').merge!(
                          {'dra7xx-evm' => 'echo enabled > /sys/devices/ocp.3/4806a000.serial/tty/ttyO0/power/wakeup',} ),
                    '3.14' => Hash.new('').merge!(
                          {'dra7xx-evm' => 'echo enabled > /sys/devices/44000000.ocp/4806a000.serial/tty/ttyO0/power/wakeup',
                           'am57xx-evm' => 'echo -n "enabled" > /sys/devices/44000000.ocp/48020000.serial/tty/ttyO2/power/wakeup', 
                          }),
                    '3.14.40' => Hash.new('').merge!(
                          {'dra7xx-evm' => 'echo enabled > /sys/devices/44000000.ocp/4806a000.serial/tty/ttyS0/power/wakeup',
                           'am57xx-evm' => 'echo -n "enabled" > /sys/devices/44000000.ocp/48020000.serial/tty/ttyS2/power/wakeup',
                          }),
                    '4.1' => Hash.new('').merge!(
                          {'dra7xx-evm' => 'echo enabled > /sys/devices/platform/44000000.ocp/4806a000.serial/tty/ttyS0/power/wakeup',
                           'dra72x-evm' => 'echo enabled > /sys/devices/platform/44000000.ocp/4806a000.serial/tty/ttyS0/power/wakeup',
                           'am57xx-evm' => 'echo -n "enabled" > /sys/devices/platform/44000000.ocp/48020000.serial/tty/ttyS2/power/wakeup',
                          }),
    },
    'enable_usb_wakeup' => { 
                    '0.0' => Hash.new('').merge!(
                          {'am335x-evm' => 'lst=`find /sys/devices/ocp.2/47400000.usb/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',
                           'am43xx-epos' => 'lst=`find /sys/devices/44000000.ocp/483c0000.omap_dwc3_2/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',
                           'am43xx-gpevm' => 'lst=`find /sys/devices/44000000.ocp/483c0000.omap_dwc3_2/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',} ),
                    '3.14' => Hash.new('').merge!(
                          {'am335x-evm' => 'lst=`find /sys/devices/ocp/47400000.usb/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',
                           'am43xx-gpevm' => 'lst=`find /sys/devices/44000000.ocp/483c0000.omap_dwc3/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',} ),
                    '3.14.43' => Hash.new('').merge!(
                          {'am335x-evm' => 'lst=`find /sys/devices/ocp/47400000.usb/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',
                           'am43xx-epos' => 'lst=`find /sys/devices/44000000.ocp/*ocp2scp*/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',
                           'am43xx-gpevm' => 'lst=`find /sys/devices/44000000.ocp/*ocp2scp*/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',} ),
                    '4.1' => Hash.new('').merge!(
                          {'am335x-evm' => 'lst=`find /sys/devices/platform/ocp/47400000.usb/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',
                           'am43xx-epos' => 'lst=`find /sys/devices/platform/44000000.ocp/*ocp2scp*/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',
                           'am43xx-gpevm' => 'lst=`find /sys/devices/platform/44000000.ocp/*ocp2scp*/ -name wakeup`; for ent in $lst; do echo $ent; echo enabled > $ent; done',} ),
    },
    'disable_usb_wakeup' => { 
                    '0.0' => Hash.new('').merge!(
                          {'am335x-evm' => 'lst=`find /sys/devices/ocp.2/47400000.usb/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',
                           'am43xx-epos' => 'lst=`find /sys/devices/44000000.ocp/483c0000.omap_dwc3_2/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',
                           'am43xx-gpevm' => 'lst=`find /sys/devices/44000000.ocp/483c0000.omap_dwc3_2/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',} ),
                    '3.14' => Hash.new('').merge!(
                          {'am335x-evm' => 'lst=`find /sys/devices/ocp/47400000.usb/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',
                           'am43xx-epos' => 'lst=`find /sys/devices/44000000.ocp/ocp2scp.* -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',
                           'am43xx-gpevm' => 'lst=`find /sys/devices/44000000.ocp/ocp2scp.* -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',} ),
                    '3.14.43' => Hash.new('').merge!(
                          {'am335x-evm' => 'lst=`find /sys/devices/ocp/47400000.usb/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',
                           'am43xx-epos' => 'lst=`find /sys/devices/44000000.ocp/*ocp2scp*/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',
                           'am43xx-gpevm' => 'lst=`find /sys/devices/44000000.ocp/*ocp2scp*/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',} ),
                    '4.1' => Hash.new('').merge!(
                          {'am335x-evm' => 'lst=`find /sys/devices/platform/ocp/47400000.usb/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',
                           'am43xx-epos' => 'lst=`find /sys/devices/platform/44000000.ocp/*ocp2scp*/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',
                           'am43xx-gpevm' => 'lst=`find /sys/devices/platform/44000000.ocp/*ocp2scp*/ -name wakeup`; for ent in $lst; do echo $ent; echo disabled > $ent; done',} ),
    },
    'disable_tsc_wakeup' => { 
                    '0.0' => Hash.new('').merge!(
                          {'am335x-evm' => 'echo disabled > /sys/devices/ocp.2/44e0d000.tscadc/power/wakeup',
                           'am43xx-epos'=> 'echo disabled > /sys/devices/44000000.ocp/44e0d000.tscadc/power/wakeup',
                           'am43xx-gpevm'=> 'echo disabled > /sys/devices/44000000.ocp/44e0d000.tscadc/power/wakeup',} ),
                    '3.14' => Hash.new('').merge!(
                          {'am335x-evm' => 'echo disabled > /sys/devices/ocp/44e0d000.tscadc/power/wakeup',
                           'am43xx-epos'=> 'echo disabled > /sys/devices/44000000.ocp/44e0d000.tscadc/power/wakeup',
                           'am43xx-gpevm'=> 'echo disabled > /sys/devices/44000000.ocp/44e0d000.tscadc/power/wakeup',} ),
                    '4.1' => Hash.new('').merge!(
                          {'am335x-evm' => 'echo disabled > /sys/devices/platform/ocp/44e0d000.tscadc/power/wakeup',
                           'am43xx-epos'=> 'echo disabled > /sys/devices/platform/44000000.ocp/44e0d000.tscadc/power/wakeup',
                           'am43xx-gpevm'=> 'echo disabled > /sys/devices/platform/44000000.ocp/44e0d000.tscadc/power/wakeup',} ),
    },
    'disable_adc_wakeup' => { 
                    '0.0' => Hash.new('').merge!(
                          {'am43xx-epos'=> 'echo "Disabling MAGADC"; devmem2 0x44DF8A30 w 0x2; devmem2 0x4834C040 w 0x70; devmem2 0x4834C058 w 0x2000000; devmem2 0x44DF8A30 w 0x0',
                           'am43xx-gpevm'=> 'echo "Disabling MAGADC"; devmem2 0x44DF8A30 w 0x2; devmem2 0x4834C040 w 0x70; devmem2 0x4834C058 w 0x2000000; devmem2 0x44DF8A30 w 0x0',} ),
    },
    'enable_gpio_wakeup' => { 
                    '0.0' => Hash.new('').merge!(
                          {
                            # set gpmc_ad15 to mux 14, which corresponds to gpio1_21 that is connected to sw3 port 8
                            'dra7xx-evm' => 'devmem2 0x4a00343c w 0x0007000e; echo 21  > /sys/class/gpio/export; echo rising > /sys/class/gpio/gpio21/edge; #GPIO_LINE=21',
                            # set spi0_sclk to mux 7, which corresponds to gpio0_2 that is connected to sw9 (Volume Up) on GP daughter card.
                            'am335x-evm' => 'cat /proc/interrupts | egrep -i GPIO[[:blank:]]+2[[:blank:]] || (devmem2 0x44e10950 w 0x00000027; echo 2  > /sys/class/gpio/export; echo rising > /sys/class/gpio/gpio2/edge); #GPIO_LINE=2',
                            # set spi0_sclk to mux 7, which corresponds to gpio0_2 (0-based) that is connected to J10-pin17
                            'am437x-sk' => 'devmem2 0x44e10950 w 0x00060007; echo 3  > /sys/class/gpio/export; echo rising > /sys/class/gpio/gpio3/edge; #GPIO_LINE=3',
                          }),
    },
    'enable_palmas_wakeup' => { 
                    '0.0' => Hash.new('').merge!(
                          {'am57xx-evm' => 'echo -n "enabled" > /sys/devices/44000000.ocp/48070000.i2c/i2c-0/0-0058/power/wakeup',} ),
                    '4.1' => Hash.new('').merge!(
                          {'am57xx-evm' => 'echo -n "enabled" > /sys/devices/platform/44000000.ocp/48070000.i2c/i2c-0/0-0058/power/wakeup',} ),
    },
    'enable_rtc_wakeup' => { 
                    '0.0' => Hash.new('').merge!(
                          {'am57xx-evm' => 'echo -n "enabled" > /sys/devices/44000000.ocp/48060000.i2c/i2c-2/2-006f/power/wakeup',} ),
                    '4.1' => Hash.new('').merge!(
                          {'am57xx-evm' => 'echo -n "enabled" > /sys/devices/platform/44000000.ocp/48060000.i2c/i2c-2/2-006f/power/wakeup',} ),
    },

    'nand_kernel_part_name' => {
                    '0.0' => 'kernel',
    },
    'nand_dtb_part_name' => {
                    '0.0' => 'u-boot-spl-os',
    },
    'nand_rootfs_part_name' => {
                    '0.0' => 'file system',
                    '3.12.0' => 'file-system',
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
  def self.get_bmc_cmd(params)
    params.merge!({'dict' => @dict_bmc})
    get_cmd(params)
  end

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
