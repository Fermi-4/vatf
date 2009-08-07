
module DrvifCfg
def send_drvif_cfg()
    send_cmd("cd \/APP",/OK/,2)
    send_cmd("\.\/drvif",/OK/,2)

    send_cmd("fpga load evm-fpga",/OK/,2)
    send_cmd("cpld mreg 0x4 0x11ff",/OK/,2)
    send_cmd("efpga mreg 0x2 0x1ff",/OK/,2)
    send_cmd("efpga mreg 0x10 0x80e8",/OK/,2)
    send_cmd("exit")
    send_cmd("\. \/mnt\/board\/evmaddr\.sh",/OK/,2)
    send_cmd("export PATH=$PATH\:\/usr\/bin\:\/bin\:\/usr\/sbin\:\/sbin\:\/bin\:\/usr\/bin\:\/usr\/sbin\:\/usr\/local\/bin\:\/APP",/OK/,2)
    send_cmd("stty erase \^H",/OK/,2)

    send_cmd("\.\/dimtestvi",/Escaping to MXP command shell/,2)
end

end
