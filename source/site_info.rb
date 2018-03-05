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
   SCLTE_LOGS_FOLDER            = '/mnt/gtsnowball/Automation/gtsystst/SCLTE'
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
   SCLTE_LOGS_FOLDER            = '//gtsnowball/System_Test/Automation/gtsystst/SCLTE'
   BENCH_FILE                   = 'C:/VATF/bench.rb'
   RESULTS_FILE                 = 'C:/VATF/vatf_automation_results.xml'
 end
 
 #LOGS_SERVER                    = "http://automationlogs.gt.design.ti.com/gtsystst_logs/vatf"
 COREDUMP_UTIL                  = "http://tigt_qa.gt.design.ti.com/qacm/test_area/nightlytools/testautomation/coredump.tar.gz"
 LOGS_SERVER                    = "http://gtsystest.telogy.design.ti.com/vatf"
 # Analytics server is specific to TMS project (e.g. Testlink project)
 ANALYTICS_SERVER               = {1140921 => "lcpdresults.itg.ti.com:80",
                                   1862381 => "gttestauto.am.dhcp.ti.com:80",
                                   3935761 => "lcpdresults.itg.ti.com:80",
                                   '' => '',
                                   }
 WINCE_DOWNLOAD_APP             = 'cedownload.exe'
 WINCE_PERFTOCSV_APP            = 'perftocsv.exe'
 VGDK_OUTPUT_CLIPS		= "//10.218.100.223/video_files/VGDK_logs/output"

end
