module SiteInfo
 SITE_MAIL_SERVER               = 'smtp.mail.ti.com'    # e-mail server to use to send test results e-mail notifications
 NETWORK_REFERENCE_FILES_FOLDER = '//10.218.111.203/VISA/'      # TODO: Make sure this is the right place
 LOCAL_FILES_FOLDER             = 'C:/Video_tools/'
 LOGS_FOLDER                    = "//gtsnowball/System_Test/Automation/gtsystst_logs/video"
 LOGS_SERVER                    = "http://gtsystest.telogy.design.ti.com/video"
 UTILS_FOLDER                   = 'C:/vatf/bin/'
 WINCE_DOWNLOAD_APP             = 'cedownload.exe'
 WINCE_PERFTOCSV_APP            = 'perftocsv.exe'
 WINCE_TEMP_FOLDER              = 'C:/vatf/data/wince/temp'

 Bootargs        = {
                'dm6467' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=80M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm6467t' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=80M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm355'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm357'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm644x' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm644x-810' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm365' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4',
                'da8xx' => 'console=ttyS2,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=32M',
               }
end
