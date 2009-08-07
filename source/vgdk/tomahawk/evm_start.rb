

module EVMStart
def send_evm_start()


    # dut = dut_id
    # ; Source MAC address for Voice Channel
    # ; Note the name of the string is fixed "dspMacVoiceSrc" prefixes
    # ; dsp_core followed by MAC address index.
    send_cmd("wait 10", /OK/, 2)
    send_cmd("dim timeout 10000 51000", /OK/, 2)

    # ;HW Config 2
    send_cmd("dimt set template 40 hw_config2 emif_cfg num_devs 1", /OK/, 2)
    send_cmd("dimt set template 40 hw_config2 emif_cfg dev_cfg 0 type sdram", /OK/, 2)
    send_cmd("dimt set template 40 hw_config2 emif_cfg dev_cfg 0 sdram action test", /OK/, 2)
    # ;dbgcmd "dimt set template 40 hw_config2 emif_cfg dev_cfg 0 sdram pll 30"

    # ;16 bit
    # ;dimt set template 40 hw_config2 emif_cfg dev_cfg 0 sdram config 0x534832
    # ;32 bit
    send_cmd("dimt set template 40 hw_config2 emif_cfg dev_cfg 0 sdram config 0x530832", /OK/, 2)
    send_cmd("dimt set template 40 hw_config2 emif_cfg dev_cfg 0 sdram refresh 0x73b", /OK/, 2)
    send_cmd("dimt set template 40 hw_config2 emif_cfg dev_cfg 0 sdram timing1 0x47245bd2", /OK/, 2)
    send_cmd("dimt set template 40 hw_config2 emif_cfg dev_cfg 0 sdram timing2 0x0125dc44", /OK/, 2)

    #; Packet Port Configuration
    send_cmd("dimt set template 10 dsp_glob_config pkt_cfg if_type mac", /OK/, 2)
    send_cmd("dimt set template 10 dsp_glob_config pkt_cfg mac num_mac_ports 1", /OK/, 2)
    send_cmd("dimt set template 10 dsp_glob_config pkt_cfg mac port 0 port_num 0", /OK/, 2)
    send_cmd("dimt set template 10 dsp_glob_config pkt_cfg mac port 0 cfg_bfield  init add_addr", /OK/, 2)
    send_cmd("dimt set template 10 dsp_glob_config pkt_cfg mac port 0 type rgmii", /OK/, 2)
    send_cmd("dimt set template 10 dsp_glob_config pkt_cfg mac port 0 duplex full", /OK/, 2)
    send_cmd("dimt set template 10 dsp_glob_config pkt_cfg mac port 0 flow_ctrl disable", /OK/, 2)

    #; Port Configuration 
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg num_ports 3", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 phy_port_num 0", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 companding mulaw", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 port_ctl init", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg data_delay 2", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg bdx_delay_ctl disable", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg idle_drive z", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg fsync_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg fsync_clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg clk_rate single", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg ts_per_frame 256", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg data_rate 16", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg clk_rdndc red", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg clk_source A", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init tx_cfg word_size 8", /OK/, 2)

    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg data_delay 1", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg bdx_delay_ctl disable", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg idle_drive z", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg fsync_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg fsync_clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg clk_rate single", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg ts_per_frame 256", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg data_rate 16", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg clk_rdndc red", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg clk_source A", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 0 ctl_cfg init rx_cfg word_size 8", /OK/, 2)


    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 phy_port_num 1", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 companding mulaw", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 port_ctl init", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg data_delay 2", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg bdx_delay_ctl disable", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg idle_drive z", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg fsync_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg fsync_clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg clk_rate single", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg ts_per_frame 256", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg data_rate 16", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg clk_rdndc red", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg clk_source A", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init tx_cfg word_size 8", /OK/, 2)

    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg data_delay 1", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg bdx_delay_ctl disable", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg idle_drive z", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg fsync_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg fsync_clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg clk_rate single", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg ts_per_frame 256", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg data_rate 16", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg clk_rdndc red", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg clk_source A", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 1 ctl_cfg init rx_cfg word_size 8", /OK/, 2)	

    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 phy_port_num 2", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 companding mulaw", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 port_ctl init", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg data_delay 1", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg bdx_delay_ctl disable", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg idle_drive z", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg fsync_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg fsync_clk_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg clk_polarity noinv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg clk_rate single", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg ts_per_frame 128", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg data_rate 8", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg clk_rdndc red", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg clk_source A", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init tx_cfg word_size 8", /OK/, 2)

    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg data_delay 0", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg bdx_delay_ctl enable", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg idle_drive z", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg fsync_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg fsync_clk_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg clk_polarity inv", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg clk_rate single", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg ts_per_frame 128", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg data_rate 8", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg clk_rdndc red", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg clk_source A", /OK/, 2)
    # send_cmd("dimt set template 10 dsp_glob_config tdm_cfg port_cfg 2 ctl_cfg init rx_cfg word_size 8", /OK/, 2)

    send_cmd("dim dbg_5561 dnld_delay_run 100", /OK/, 2)

    #;Disable Reliable message 
    #;dim opt 100001
    send_cmd("dim opt 3", /OK/, 2)

    #;spy dim_dnld 2

    #; Pre-download the DSP
    #;cc dnld 0 0 40

    send_cmd("dspi load \/APP\/dspi\/tv01\.ld", /OK/, 2)

    send_cmd("cc dnld 0 0 40", /OK/, 2)

    send_cmd("wait 10", /OK/, 2)
    send_cmd("cc dnld 1 0 40", /OK/, 2)
    send_cmd("wait 10", /OK/, 2)
    send_cmd("cc dnld 2 0 40", /OK/, 2)
    send_cmd("wait 10", /OK/, 2)
    send_cmd("cc dnld 3 0 40", /OK/, 2)
    send_cmd("wait 10", /OK/, 2)
    send_cmd("cc dnld 4 0 40", /OK/, 2)
    send_cmd("wait 10", /OK/, 2)
    send_cmd("cc dnld 5 0 40", /OK/, 2)
    send_cmd("wait 10000", /OK/, 2)
    # send_cmd("spy dim 2", /OK/, 2)

end

end







