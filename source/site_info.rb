module SiteInfo
 SITE_MAIL_SERVER               = 'smtp.mail.ti.com'    # e-mail server to use to send test results e-mail notifications
 # NETWORK_REFERENCE_FILES_FOLDER = '//10.218.111.203/VISA/'      # TODO: Make sure this is the right place
 
 if OsFunctions::is_linux?       
   FILE_SERVER                  = '/mnt/gtautoftp'
   LOGS_FOLDER                  = '/mnt/gtsnowball/Automation/gtsystst_logs/vatf'
   UTILS_FOLDER                 = '/usr/local/vatf/bin/'
   WINCE_DATA_FOLDER            = '/usr/local/vatf/data/wince'
   LINUX_TEMP_FOLDER            = '/usr/local/vatf/data/linux/temp'
   LOCAL_FILES_FOLDER           = '/usr/local/vatf/Video_tools/'
   VGDK_INPUT_CLIPS             = "/mnt/gtsnowball/Automation/gtsystst/video_files/VGDK_logs/input"
   LTP_TEMP_FOLDER              = '/mnt/gtsnowball/Automation/gtsystst/LTP'
   BENCH_FILE                   = '/usr/local/vatf/bench.rb'
   RESULTS_FILE                 = '/usr/local/vatf/vatf_automation_results.xml'
 else
   FILE_SERVER                  = '//gtautoftp/tftpboot/anonymous'
   LOGS_FOLDER                  = "//gtsnowball/System_Test/Automation/gtsystst_logs/vatf"
   UTILS_FOLDER                 = 'C:/vatf/bin/'
   WINCE_DATA_FOLDER            = 'C:/vatf/data/wince'
   LINUX_TEMP_FOLDER            = 'C:/vatf/data/linux/temp'
   LOCAL_FILES_FOLDER           = 'C:/Video_tools/'
   VGDK_INPUT_CLIPS             = "//gtsnowball/System_Test/Automation/gtsystst/video_files/VGDK_logs/input"
   LTP_TEMP_FOLDER              = '//gtsnowball/System_Test/Automation/gtsystst/LTP'
   BENCH_FILE                   = 'C:/VATF/bench.rb'
   RESULTS_FILE                 = 'C:/VATF/vatf_automation_results.xml'
 end
 
 LOGS_SERVER                    = "http://gtsystest.telogy.design.ti.com/vatf"
 WINCE_DOWNLOAD_APP             = 'cedownload.exe'
 WINCE_PERFTOCSV_APP            = 'perftocsv.exe'
 VGDK_OUTPUT_CLIPS				      = "//10.218.100.223/video_files/VGDK_logs/output"

 Bootargs        = {
                'dm6467' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=80M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm6467t' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=80M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm355'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm357'  => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm644x' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm644x-810' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=116M davinci_enc_mngr.ch0_mode=NTSC davinci_enc_mngr.ch0_output=COMPOSITE',
                'dm365' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=80M video=davincifb:vid0=OFF:vid1=OFF:osd0=720x576x16,4050K dm365_imp.oper_mode=0 davinci_capture.device_type=4',
                'am37x' => 'console=ttyS0,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock',
                'da8xx' => 'console=ttyS2,115200n8 noinitrd ip=dhcp root=/dev/nfs rw nfsroot=${nfs_root_path},nolock mem=32M',
               }
end
