using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using System.Reflection;
using System.Threading;
using System.Text.RegularExpressions;
using System.Diagnostics;
using System.IO;
using System.Xml;

namespace TeHandlers
{
    public class QmasterDllDriver
    {
        private Process qmasterHandle;
        private QmasterLogger qmLogger;
        private StreamWriter qmWriter;
        private int threadSleepInterval = 10;
        private Thread testThread;
        private const string QMASTER_DRIVE = "Z:";
        private const string QMASTER_PASSWORD = "optimum";
        private const string QMASTER_UNAME = "remote";
        private Hashtable qmasterState = null;
        private object synchObject = new object();
        private string videoScoresPath = QMASTER_DRIVE + "\\Support Files\\video_pesq.xml";
        private const string QMASTER_CMD = "\""+QMASTER_DRIVE+"\\Support Files\\QMCommandLine.exe\" ";
        private const string QMASTER_EXE_DIR = QMASTER_DRIVE + "\\Support Files\\";
        private string wrkAroundFileBaseName;
        private string wrkAroundTestFileName;

        public QmasterDllDriver(Hashtable equipmentInfo, string logPath)
        {
            try
            {
                this.StartLogger(logPath);
                LogInfo("Starting new Q-Master Session");
                qmasterHandle = new Process();
                qmasterHandle.StartInfo.FileName = "cmd";
                qmasterHandle.StartInfo.RedirectStandardOutput = true;
                qmasterHandle.StartInfo.RedirectStandardInput = true;
                qmasterHandle.StartInfo.UseShellExecute = false;
                qmasterHandle.StartInfo.CreateNoWindow = true;
                qmasterHandle.OutputDataReceived += new DataReceivedEventHandler(ReadHandler);
                qmasterHandle.Start();
                this.qmasterHandle.BeginOutputReadLine();
                this.qmWriter = qmasterHandle.StandardInput;
                //MapDrive((string)equipmentInfo["telnet_ip"]);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        public void StartLogger(string logPath)
        {
            this.qmLogger = new QmasterLogger(this.ToString(), logPath);
        }

        public void StopLogger()
        {
            if (this.qmLogger != null) this.qmLogger.CloseLogger();
        }

        public void EndSession()
        {
            if (this.qmasterHandle != null)
            {
                this.qmasterHandle.Kill();
                this.qmasterHandle.WaitForExit();
            }
        }

        public void QmWrite(string message)
        {
            LogInfo("Command: "+message);
            this.qmWriter.WriteLine(message);
        }

        public int WaitForAck(int timeout)
        {
            int triesCount = 0;
            int maxTries = (int)Math.Round((double)timeout / (double)this.threadSleepInterval);
            while (this.testThread.IsAlive && triesCount < maxTries)
            {
                triesCount++;
                Thread.Sleep(this.threadSleepInterval);
            }
            if (this.testThread.IsAlive)
            {
                this.testThread.Abort();
            }
            this.testThread.Join();
            return (int)this.qmasterState["result"];
        }

        public void Calibrate(Hashtable calInfo)
        {
            string[] refArray = CreateCodesrcFile((string)calInfo["ref_file"]);
            string codesrcRefFile = refArray[0];
            string uncompRefFile = refArray[1];
            string refBase = refArray[2];
            Hashtable calTestInfo = new Hashtable();
            calTestInfo["ref_file"] = codesrcRefFile;
            calTestInfo["test_file"] = "cal_clip.avi";
            calTestInfo["video_io_mode"] = 7;
            calTestInfo["ref_file_type"] = 1;
            calTestInfo["uncompress_ref"] = uncompRefFile;
            calTestInfo["video_out_pal"] = (bool)calInfo["is_pal"];
            calTestInfo["video_calibration"] = true;
            TestVideo(calTestInfo);
            if (!QmExpect("OK",120000))
            {
                QmAbort();
                throw new Exception("Unable to calibrate Q-Master for file "+refBase);
            }
            Regex resParser = new Regex("\\w*_(?<resolution>\\d+x\\d+)_\\w*");
            string resolution = resParser.Match(refBase.ToLower()).Groups["resolution"].Value;
    	    if (File.Exists(QMASTER_EXE_DIR+"CalReport.txt") && resolution != null)
            {
                File.Copy(QMASTER_EXE_DIR + "CalReport.txt", QMASTER_EXE_DIR + resolution + "_CalReport.txt", true); 
            }
            else
            {
                throw new Exception("Unable to calibrate Q-Master with file "+refBase);
            }
        }

        public void H264EncodeFile(string inputFile, string outputFile, Hashtable encoderSettings)
        {
            Hashtable h264GuidHash = new Hashtable();
            h264GuidHash["enc_preset"] = "EMC_PRESET";    
            h264GuidHash["video_format"] = "EH264VE_VideoFormat";
            h264GuidHash["enc_profile"] = "EMC_PROFILE";
            h264GuidHash["enc_level"] = "EMC_LEVEL";
            h264GuidHash["enc_avg_bitrate"] = "EMC_BITRATE_AVG";
            h264GuidHash["enc_bitrate_mode"] = "EMC_BITRATE_MODE";
            h264GuidHash["enc_max_bitrate"] = "EMC_BITRATE_MAX";
            h264GuidHash["enc_stream_type"] = "EH264VE_stream_type";

            QmHashTable encSettings = new QmHashTable();
            encSettings["enc_preset"] = 0;  // values: 0 VideoType_BASELINE, 1 VideoType_CIF, 2 VideoType_MAIN, 3 VideoType_SVCD, 4 VideoType_D1, 5 VideoType_HIGH, 6 VideoType_DVD, 7 VideoType_HD_DVD, 8 VideoType_BD, 9 VideoType_BD_HDMV, 10 VideoType_PSP, 11 VideoType_HDV_HD1, 12 VideoType_HDV_HD2, 13 VideoType_iPOD
            encSettings["video_format"] = 0; // values: 0 VideoFormat_Auto, 1 VideoFormat_PAL, 2 VideoFormat_NTSC, 3 VideoFormat_SECAM, 4 VideoFormat_MAC, 5 VideoFormat_Unspecified 
            encSettings["enc_profile"] = 0; // values: 0 Profile_Baseline, 1 Profile_Main, 3 Profile_High
            encSettings["enc_level"] = 100; // values: 10 Level_1, 11 Level_1.1, 12 Level_1.2, 13 Level_1.3, 20 Level_2, 21 Level_2.1, 22 Level_2.2, 30 Level_3, 31 Level_3.1, 32 Level_3.2, 40 Level_4, 41 Level_4.1, 42 Level_4.2, 50 Level_5, 51 Level_5.1, 100 Level_Auto      
            encSettings["enc_avg_bitrate"] = 6000000; // values: [1024,288000000]
            encSettings["enc_bitrate_mode"] = 2; // values: 0 BitRateMode_CBR Constant bitrate, 1 BitRateMode_CQT Constant quantization parameter, 2 BitRateMode_VBR Variable bitrate.
            encSettings["enc_max_bitrate"] = 6600000; // values: [enc_avg_bitrate, 288000000]
            encSettings["enc_stream_type"] = 2; // values: 0 StreamTypeI Stream type I according to AVC/H.264 specification, 1 StreamTypeIplusSEI - Stream type I plus SEI messages, 2 StreamTypeII - Stream type II

            encSettings.Merge(encoderSettings);
            CreateCodecInputFile("H264_Enc_Input.txt", h264GuidHash, encSettings);
            this.EncodeDecodeFile("h264", true, inputFile, outputFile);
        }
   
        public void Mpeg4EncodeFile(string inputFile, string outputFile, Hashtable encoderSettings)
        {
            Hashtable mpeg4GuidHash = new Hashtable();
            mpeg4GuidHash["enc_quality"] = "EM4VE_Quality";    
    		mpeg4GuidHash["enc_avg_bitrate"] = "EMC_BITRATE_AVG";
    		mpeg4GuidHash["enc_bitrate_mode"] = "EMC_BITRATE_MODE";
            mpeg4GuidHash["enc_profile"] = "EM4VE_Profile";
            mpeg4GuidHash["enc_level"] = "EMC_LEVEL";

            QmHashTable encSettings = new QmHashTable();
            encSettings["enc_quality"] = 13;  // values: [0,15] , 0 low, 15 high
		    encSettings["enc_avg_bitrate"] = 6000000; // values: Level restricted, 
		    encSettings["enc_bitrate_mode"] = 2; // values: 0 CBR, 1 VBR, 2 Const Quality, 3 Const quantizer 
		    encSettings["enc_profile"] = 0; // values: 0 - Simple; 1 - Advanced simple 
            encSettings["enc_level"] = 3; // values: [0 - 3]

            encSettings.Merge(encoderSettings);
            this.CreateCodecInputFile("MPEG4_Enc_Input.txt", mpeg4GuidHash, encSettings);
            this.EncodeDecodeFile("mpeg4", true, inputFile, outputFile);
        }

        public void H264DecodeFile(string inputFile, string outputFile, Hashtable decoderSettings)
        {
            Hashtable h264GuidHash = new Hashtable();
            h264GuidHash["dec_skip_mode"] = "EH264VD_SkipMode";    
		    h264GuidHash["dec_error_resilience"] = "EH264VD_ErrorResilience";
		    h264GuidHash["dec_deblocking"] = "EH264VD_Deblock";
		    h264GuidHash["dec_deinterlace"] = "EH264VD_Deinterlace";
		    h264GuidHash["dec_upsampling"] = "EH264VD_HQUpsample";
		    h264GuidHash["dec_double_rate"] = "EH264VD_DoubleRate";
		    h264GuidHash["dec_fields_reordering"] = "EH264VD_FieldsReordering";
		    h264GuidHash["dec_reorder_condition"] = "EH264VD_FieldsReorderingCondition";
            h264GuidHash["dec_synch"] = "EH264VD_SYNCHRONIZING";

            QmHashTable decSettings = new QmHashTable();
            decSettings["dec_skip_mode"] = 1;  // values: [0,4], 0 Respect quality messages from upstream filter, 1 Decode all frames do not skip, 2 Skip all non-reference frames, 3 Skip B frames even if they are used as reference, 4 Skip P and B frames even if they are used as reference.
		    decSettings["dec_error_resilience"] = 2; // values: [0, 2], 0 If bit stream error is detected skip all slices until first intra slice, 1 If bit stream error is detected skip all slices until first IDR slice, 2 Ignore bit stream errors 
		    decSettings["dec_deblocking"] = 0; // values: [0, 2], 0 Respect in-loop filter control parameters specified by the bit stream, 1 Run in-loop filter only for reference pictures, 3 Skip in-loop filter for all pictures
		    decSettings["dec_deinterlace"] = 0; // values: [0, 4], 0 Do not deinterlace output interleaved fields, 1 Deinterlace by vertical smooth filter, 2 Deinterlace by interpolation one field from another, 3 Deinterlace by means of VMR (Video Mixing Renderer). It is possible only if the filter is connected to VMR or OveralyMixer, 4 Automatic deinterlace if type of picture is field or MBAFF. If decoder works in DXVA mode then the VMR deinterlace will be applied. If decoder works in software mode then the field interpolation deinterlace will be applied      
	        decSettings["dec_upsampling"] = 0; // values: [0, 1], 0 Sets the fast mode, 1 Sets the polyphase filter use. 
	        decSettings["dec_double_rate"] = 0; // values: [0, 1], 0 Feature is disabled, 1 Feature is enabled
	        decSettings["dec_fields_reordering"] = 0; // values: [0, 2],  0 Feature is disabled, 1 Fields are reordered by inverting the specific media sample flags, 2 Fields are reordered by exchanging the fields in picture 
	        decSettings["dec_reorder_condition"] = 2; // values: [0, 2], 0 Always, 1 If TopFirst flag is TRUE, 2 If TopFirst flag is FALSE			
            decSettings["dec_synch"] = 0; // values: [0, 2], 0 Synchronizing_PTS, 1 Synchronizing_IgnorePTS_NotRef, 2 Synchronizing_IgnorePTS_All 

            decSettings.Merge(decoderSettings);
            this.CreateCodecInputFile("H264_Dec_Input.txt", h264GuidHash, decSettings);
            this.EncodeDecodeFile("h264", false, inputFile, outputFile);

        }
      
        public void Mpeg4DecodeFile(string inputFile, string outputFile, Hashtable decoderSettings)
        {
            Hashtable mpeg4GuidHash = new Hashtable();
            mpeg4GuidHash["dec_skip_mode"] = "EM4VD_SkipOutOfTimeFrames";    
		    mpeg4GuidHash["dec_post_processing"] = "EM4VD_PostProcessing";
		    mpeg4GuidHash["dec_brightness"] = "EM4VD_Brightness";
		    mpeg4GuidHash["dec_contrast"] = "EM4VD_Contrast";
            mpeg4GuidHash["dec_gop_mode"] = "EM4VD_GopDecMode";

            QmHashTable decSettings = new QmHashTable();
            decSettings["dec_skip_mode"] = 0;  // values: [0,1], 0 All the frames should be decoded, 1 skip out of time B-frames
		    decSettings["dec_post_processing"] = 0; // values: [0, 1], 0 dont't use post processing, 1 Deblocking filter must be applied to decoded pictures
		    decSettings["dec_brightness"] = 750; // values: [0, 10000], brightness
		    decSettings["dec_contrast"] = 10000; // values: [0, 20000], contrast
            decSettings["dec_gop_mode"] = 0; // values: [0, 2], 0 Decode all types of vops, 1 decode I and P-Vops, 2 decode only I-VOPs 

            decSettings.Merge(decoderSettings);

            this.CreateCodecInputFile("MPEG4_Dec_Input.txt", mpeg4GuidHash, decSettings);
            this.EncodeDecodeFile("mpeg4", false, inputFile, outputFile);
        }

        public void GetCodesrcH264EncodedFile(string aviRefFile, string h264EncFile, Hashtable encoderSettings)
        {
            string codesrcRefFile = GetCodesrcFilePath(aviRefFile);
            if (codesrcRefFile.Length <= 0)
            {
                throw new Exception("Codesrc file does not exist for " + aviRefFile);
            }
            this.H264EncodeFile(codesrcRefFile, h264EncFile, encoderSettings);
        }

        public void GetCodesrcMpeg4EncodedFile(string aviRefFile, string mpeg4EncFile, Hashtable encoderSettings)
        {
            string codesrcRefFile = GetCodesrcFilePath(aviRefFile);
            if (codesrcRefFile.Length <= 0)
            {
                throw new Exception("Codesrc file does not exist for " + aviRefFile);
            }
            this.Mpeg4EncodeFile(codesrcRefFile, mpeg4EncFile, encoderSettings);
        }

        public void CompositeOutToCompositeInTest(string refClip, string testClip, bool isPal)
        {
            string[] testFiles = CreateCodesrcFile(refClip);

            Hashtable testParams = new Hashtable();
            testParams["ref_file"] = testFiles[0];
            testParams["test_file"] = testClip;
            testParams["video_io_mode"] = 7;
            testParams["ref_file_type"] = 1;
            testParams["uncompress_ref"] = testFiles[1];
            testParams["video_out_pal"] = isPal;

            this.SetWrkAroundFiles(refClip, testClip); //Needed for workaround

            this.TestVideo(testParams);
        }

        /**This functions is here due to the workaround needed for tests involving analog IO, once the workaround is no longer needed this function should be removed
         */
        //ANALOG_TESTS_WORKAROUND
        public int WaitForAnalogTestAck(int timeout)
        {
            int result = this.WaitForAck(timeout);
            if ( result == 0)
            {
                result = this.FileToFileTest("workaround_ref_" + this.wrkAroundFileBaseName, QMASTER_DRIVE + "\\Video\\User Defined Files\\Test Files\\" + this.wrkAroundTestFileName, false);
            }

            return result;
        }
        //END_OF_ANALOG_TESTS_WORKAROUND
     
        public void FileToCompositeInTest(string refFile, string testClip, bool isPredefined, bool isPal, bool isComposite)
        {
            Hashtable testParams = new Hashtable();
            
            if (isPredefined)
            {
                testParams["ref_file_type"] = 1;
            }
            else
            {
                testParams["ref_file_type"] = 0;
            }

            if (isComposite)
            {
                testParams["video_io_mode"] = 1;
            }
            else
            {
                testParams["video_io_mode"] = 2;
            }

            string[] testFiles = this.CreateCodesrcFile(refFile);
            testParams["ref_file"] = testFiles[0];
            testParams["test_file"] = testClip;
            testParams["ref_file_type"] = 1;
            testParams["uncompress_ref"] = testFiles[1];
            testParams["video_out_pal"] = isPal;

            this.SetWrkAroundFiles(refFile, testClip); //Needed for workaround

            this.TestVideo(testParams);
        }

        public int FileToFileTest(string refFile, string testFile, bool useMarkers)
        {
            string refFileName = this.GetFileBaseName(refFile);
            string testFileName = this.GetFileBaseName(testFile);
            string filesDir = "";
            Hashtable testParams = new Hashtable();
            testParams["test_file"] = testFileName;
            testParams["ref_file_type"] = 2;
            int result;
            try
            {
                if (useMarkers)
                {
                    testParams["video_io_mode"] = 1002;
                    filesDir = QMASTER_DRIVE + "\\Video\\User Defined Files\\";
                    string[] testFiles = this.CreateCodesrcFile(refFile);
                    testParams["ref_file"] = testFiles[0];
                    testParams["uncompress_ref"] = testFiles[1];
                    File.Copy(testFile, filesDir + "Test Files\\qresult.avi",true);
                }
                else
                {
                    filesDir = QMASTER_DRIVE + "\\Video\\File Mode\\";
                    if (!File.Exists(filesDir + "Reference Files\\" + refFileName))
                    {
                        File.Copy(refFile, filesDir + "Reference Files\\" + refFileName);
                    }
                    File.Copy(testFile, filesDir + "Test Files\\" + testFileName,true);
                    testParams["ref_file"] = refFileName;
                    testParams["video_io_mode"] = 0;
                }

                TestVideo(testParams);
                result = WaitForAck(300000);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
            finally
            {
                if (File.Exists(filesDir + "Test Files\\" + testFileName))
                {
                    File.Delete(filesDir + "Test Files\\" + testFileName);
                }
            }

            return result;
        }

        public void PlayCompositeOut(string srcClip, bool isPal)
        {
            string[] testFiles = CreateCodesrcFile(srcClip);

            Hashtable testParams = new Hashtable();
            testParams["ref_file"] = testFiles[0];
            testParams["test_file"] = "playout.avi";
            testParams["video_io_mode"] = 1001;
            testParams["ref_file_type"] = 1;
            testParams["uncompress_ref"] = testFiles[1];
            testParams["video_out_pal"] = isPal;

            TestVideo(testParams);
        }
    
/**
    #Generic function used to run a test. See q-master docs Remote Control chapter for parameter explanation. Takes
    #:ref_file (string): reference file used for comparison, 
    #:test_file (string): processed file that will be tested, 
    #:transmitter_ip: (string XXX.XXX.XXX.XXX format) transmitter's ip address for streaming, 
    #:transmitter_mask: (string XXX.XXX.XXX.XXX format) transmitter's network mask for streaming, 
    #:transmitter_gateway: (string XXX.XXX.XXX.XXX format) transmitter's gateway for streaming, 
    #:receiver_ip: (string XXX.XXX.XXX.XXX format) receiver's ip address for streaming, 
    #:receiver_mask: (string XXX.XXX.XXX.XXX format) receiver's mask for streaming, 
    #:receiver_gateway: (string XXX.XXX.XXX.XXX format) receiver's gateway for streaming,
    #:stream_protocol: (number) streaming protocol TCP (0) or UDP(1),
    #:video_io_mode (number): video io mode that will be used,
    #:multicast_addr: (string XXX.XXX.XXX.XXX format) for streaming ,
    #:ref_file_type (number): type of refence file depending on the test
    #:video_calibration (number): 1 calibrate analog IO, 0 do not calibrate
    #:video_out_pal: true means analog format is pal, false means analog format is NTSC
    #:uncompref_ref: (string) uncompref fiel used for video playout
    #:timeout : not used right now
 * */
        public void TestVideo(Hashtable funcParams)
        {
            QmHashTable defaultParams = new QmHashTable();
            Hashtable testParams = new Hashtable();
            defaultParams["transmitter_ip"] = "";
            defaultParams["transmitter_mask"] = "";
            defaultParams["multicast_addr"] = "";
            defaultParams["ref_file_type"] = 1;
            defaultParams["video_calibration"] = false;
            defaultParams["transmitter_gateway"] = "";
            defaultParams["receiver_ip"] = "";
            defaultParams["receiver_mask"] = "";
            defaultParams["receiver_gateway"] = "";
            defaultParams["stream_protocol"] = 1;
            defaultParams["video_out_pal"] = false;
            defaultParams["uncompress_ref"] = "";
            defaultParams["timeout"] = 0;

            defaultParams.Merge(funcParams);
            

            foreach (string currentKey in defaultParams.Keys)
            {
                if (defaultParams[currentKey].GetType() == typeof(bool))
                {
                    if ((bool)defaultParams[currentKey])
                    {
                        testParams[currentKey] = ToArgument(1);
                    }
                    else
                    {
                        testParams[currentKey] = ToArgument(0);
                    }
                }
                else
                {
                    testParams[currentKey] = ToArgument(defaultParams[currentKey]);
                }
            }
            if (File.Exists(this.videoScoresPath))File.Delete(this.videoScoresPath);
            Regex resParser = new Regex("\\w*_(?<resolution>\\d+x\\d+)_\\w*");
            string resolution = resParser.Match((string)testParams["ref_file"]).Groups["resolution"].Value;
            if (File.Exists(QMASTER_EXE_DIR + resolution + "_CalReport.txt"))
            {
                File.Copy(QMASTER_EXE_DIR + resolution + "_CalReport.txt", QMASTER_EXE_DIR + "CalReport.txt", true);
            }
            this.testThread = new Thread(new ParameterizedThreadStart(QmExpect));
            testThread.Start("OK");
            this.QmWrite(QMASTER_CMD + (string)testParams["ref_file"] + (string)testParams["test_file"] + (string)testParams["transmitter_ip"] + (string)testParams["transmitter_mask"] + (string)testParams["transmitter_gateway"] +
                        (string)testParams["receiver_ip"] + (string)testParams["receiver_mask"] + (string)testParams["receiver_gateway"] + (string)testParams["stream_protocol"] + (string)testParams["video_io_mode"] +
                        (string)testParams["multicast_addr"] + (string)testParams["ref_file_type"] + (string)testParams["video_calibration"] + (string)testParams["video_out_pal"] + (string)testParams["uncompress_ref"] +
                        (string)testParams["timeout"]);
        }

        public bool QmExpect(string expectedRegExp,int timeout)
        {
            lock (this.synchObject)
            {
                qmasterState = new Hashtable();
                this.qmasterState["receivedString"] = "";
            }
            Regex expectChecker = new Regex(expectedRegExp);
            int timeoutCount = 0;
            int timeoutCountLimit = (int)Math.Round((double)timeout / (double)this.threadSleepInterval);
            while ( timeoutCount < timeoutCountLimit && !expectChecker.Match((string)this.qmasterState["receivedString"]).Success)
            {
                Thread.Sleep(this.threadSleepInterval);
                timeoutCount++;
            }
            return expectChecker.Match((string)this.qmasterState["receivedString"]).Success;
        }

        public string GetExpectString()
        {
            if (this.qmasterState == null) return "";

            return (string)this.qmasterState["receivedString"];
        }

        public void QmAbort()
        {
            if (this.testThread != null && this.testThread.IsAlive)
            {
                this.testThread.Abort();
                this.testThread.Join();
            }
            Process abortProcess = new Process();
            abortProcess.StartInfo.FileName = QMASTER_CMD;
            abortProcess.StartInfo.RedirectStandardOutput = true;
            abortProcess.StartInfo.RedirectStandardInput = true;
            abortProcess.StartInfo.UseShellExecute = false;
            abortProcess.StartInfo.CreateNoWindow = true;
            abortProcess.Start();
            StreamReader abortReader = abortProcess.StandardOutput;
            StreamWriter abortWriter = abortProcess.StandardInput;
            string abortResponse = abortReader.ReadLine();
            while (!abortResponse.Contains("Abort"))
            {
                Thread.Sleep(this.threadSleepInterval);
                abortResponse = abortReader.ReadLine();
            }
        }

    
        public double GetMosScore()
        {
           return GetScore("MOS");
        }
          
        //Returns the mean jerkiness score of the last completed test	
        public double GetJerkinessScore()
        {
            return GetScore("Jerkiness");
        }

        //Returns the mean level score of the last completed test	
        public double GetLevelScore()
        {
            return GetScore("Level");
        }

        //Returns the mean blockiness score or the blockiness score of a particular frame (if a frame number is specified) of the last completed test 	
        public double GetBlockingScore()
        {
            return GetScore("BlockDistortion");
        }

        public double GetBlockingScore(int frame)
        {
            return GetScores("FrameBlocking")[frame];
        }

        //Returns the mean blurring score or the blurring score of a particular frame (if a frame number is specified)	of the last completed test
        public double GetBlurringScore()
        {
            return GetScore("Blurring");
        }

        public double GetBlurringScore(int frame)
        {
            return GetScores("FrameBlurring")[frame];
        }

        //Returns the total frames lost or the frames until frame (if a frame number is specified)	of the last completed test
        public double GetFrameLostCount()
        {
            return GetScore("LostFrames");
        }

        public double GetFrameLostCount(int frame)
        {
            return GetScores("FrameLostCount")[frame];
        }

        //Returns the mean psnr score or the psnr score of a particular frame (if a frame number is specified)	of the last completed test
        public double GetPsnrScore()
        {		  
            return GetScore("PSNR");
        }

        public double GetPsnrScore(int frame)
        {
            return GetScores("FramePSNR")[frame];
        }

        //Returns an array containing the blockiness score of each frame
        public double[] GetBlockingScores()
        {
            return GetScores("FrameBlocking");
        }

        //Returns an array containing the blurring score of each frame
        public double[] GetBlurringScores()
        {
            return GetScores("FrameBlurring");
        }

        //Returns an array containing the frames lost until each of the frame received was captured 
        public double[] GetFramesLostCount()
        {
            return GetScores("FrameLostCount");
        }

        //Returns an array containing the psnr score of each frame
        public double[] GetPsnrScores()
        {
            return GetScores("FramePSNR");
        }

        public double GetJitterScore()
        {
            return GetScore("FrameJitter");
        }
    

        //Generic function to retrieve the video quality scores. Takes metric (string the desired video quality metric as paramter.
        //Returns an array containing the desired metric  
        private double GetScore(string metric)
        {
            XmlTextReader videoResultsParser = new XmlTextReader(this.videoScoresPath);
            videoResultsParser.ReadToFollowing(metric);
            double result = videoResultsParser.ReadElementContentAsDouble();
            videoResultsParser.Close();
            return result;
        }

        public double[] GetScores(string metric)
        {
            ArrayList resultsArray = new ArrayList();
            XmlTextReader videoResultsParser = new XmlTextReader(this.videoScoresPath);
            videoResultsParser.ReadToFollowing(metric);
            videoResultsParser.ReadToDescendant("value");
            {
                resultsArray.Add(videoResultsParser.ReadElementContentAsDouble());
                while (videoResultsParser.ReadToNextSibling("value"))
                {
                    resultsArray.Add(videoResultsParser.ReadElementContentAsDouble());
                }
            }
            videoResultsParser.Close();
            return (double[])resultsArray.ToArray(typeof(double));
        }

        private void LogInfo(string info)
        {
            if (this.qmLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(qmLogger.LogInfo));
                logThread.Start(info);
            }
        }

        private void LogError(string error)
        {
            if (this.qmLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(qmLogger.LogError));
                logThread.Start(error);
            }
        }

        private void LogWarning(string warning)
        {
            if (this.qmLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(qmLogger.LogWarning));
                logThread.Start(warning);
            }
        }

        private void ReadHandler(object sendingProcess, DataReceivedEventArgs outLine)
        {
            try{
                if (!String.IsNullOrEmpty(outLine.Data))
                {
                    LogInfo("Response: "+outLine.Data);
                    lock (this.synchObject)
                    {
                        if (this.qmasterState != null)
                        {
                            this.qmasterState["receivedString"] += outLine.Data;
                        }
                    }
                }
            }catch(Exception e)
            {
                LogError(e.ToString());
            }
        }

        private void MapDrive(string ipAddress)
        {
            if (!this.QmSendExpect("NET USE","(OK|Disconnected)\\s+" + QMASTER_DRIVE, 5000))
            {
                this.QmWrite("NET USE " + QMASTER_DRIVE + " \"\\\\" + ipAddress + "\\Q-Master Video\" " + QMASTER_PASSWORD + " /USER:" + QMASTER_UNAME + " /PERSISTENT:YES");
                if (!this.QmExpect("The command completed successfully.", 5000))
                {
                    throw new Exception("Unablet to map drive " + QMASTER_DRIVE + " for Q-Master");
                }
            }
        }

        private bool QmSendExpect(string command, string expectedRegExp, int timeout)
        {
            lock (this.synchObject)
            {
                qmasterState = new Hashtable();
                this.qmasterState["receivedString"] = "";
            }
            this.QmWrite(command);
            Regex expectChecker = new Regex(expectedRegExp);
            int timeoutCount = 0;
            int timeoutCountLimit = (int)Math.Round((double)timeout / (double)this.threadSleepInterval);
            while (timeoutCount < timeoutCountLimit && !expectChecker.Match((string)this.qmasterState["receivedString"]).Success)
            {
                Thread.Sleep(this.threadSleepInterval);
                timeoutCount++;
            }
            return expectChecker.Match((string)this.qmasterState["receivedString"]).Success;
        }

        private void QmExpect(object expectedRegExp)
        {
            try
            {
                lock (this.synchObject)
                {
                    qmasterState = new Hashtable();
                    this.qmasterState["receivedString"] = "";
                    this.qmasterState["result"] = 2;
                }
                Regex expectChecker = new Regex((string)expectedRegExp);
                while (!expectChecker.Match((string)this.qmasterState["receivedString"]).Success)
                {
                    if (((string)this.qmasterState["receivedString"]).Contains("VQUAD failed error"))
                    {
                        return;
                    }
                    if (((string)this.qmasterState["receivedString"]).Contains("QMaster is uncalibrated"))
                    {
                        lock (this.synchObject)
                        {
                            this.qmasterState["result"] = 1;
                        }
                        return;
                    }
                    Thread.Sleep(this.threadSleepInterval);
                }
                lock (this.synchObject)
                {
                    this.qmasterState["result"] = 0;
                }
            }
            catch (Exception)
            {
            }
        }

        private string[] CreateCodesrcFile(string fileName)
        {
            string[] result = new string[3];
            string filesDir = QMASTER_DRIVE+"\\Video\\User Defined Files\\";
            string baseName = GetFileBaseName(fileName);
            string codeSrcRefFile = baseName.Replace(".avi","_codesrc.avi");
            string uncompRefFile = baseName.Replace(".avi","_uncompref.avi");
            if(!File.Exists(filesDir+"Source Files\\"+codeSrcRefFile) || !File.Exists(filesDir+"Uncompressed Reference Files\\"+uncompRefFile))
            {
                if( !File.Exists(filesDir+"Source Files\\"+baseName))
                {
                    File.Copy(fileName,filesDir+"Source Files\\"+baseName,true);
                }
                this.QmWrite(QMASTER_CMD+baseName); 
                if( !this.QmExpect("OK",300000))
                {
                    this.QmAbort();
                    throw new Exception("Unable to create codesrc file for "+fileName);
                }
            }
            result[0] = codeSrcRefFile;
            result[1] = uncompRefFile;
            result[2] = baseName;

            return result;
        }

        private string ToArgument(object arg)
        {
            return " \"" + arg.ToString() + "\"";
        }

        private void EncodeDecodeFile(string codecType, bool encode, string inputFile, string outputFile)
        {
            string inputDir = "";
            string outputDir = "";
            string inFile = "";
            string outFile = "";
            try
            {
                string filesDir = QMASTER_DRIVE + "\\Video\\File Mode\\";
                if (File.Exists(QMASTER_EXE_DIR + "cmdout.txt"))
                {
                    File.Delete(QMASTER_EXE_DIR + "cmdout.txt");
                }
                string codecCmd = "";
                switch (codecType.Trim().ToLower())
                {
                    case "h264":
                        codecCmd += "H264";
                        break;
                    case "mpeg4":
                        codecCmd += "MPG4";
                        break;
                    default:
                        throw new Exception("Unsupported codec " + codecType);

                }
                inFile = GetFileBaseName(inputFile);             
                if (encode)
                {
                    codecCmd += "Encoder.exe";
                    inputDir = filesDir + "Decoded Files\\";
                    outputDir = filesDir + "Encoded Files\\";
                }
                else
                {
                    codecCmd += "Decoder.exe";
                    inputDir = filesDir + "Encoded Files\\";                  
                    outputDir = filesDir + "Decoded Files\\";
                }
                File.Copy(inputFile, inputDir + inFile, true);
                outFile = GetFileBaseName(outputFile);
                this.QmWrite(QMASTER_CMD + "-r " + ToArgument(codecCmd + " -i " + inFile + " -o " + outFile));
                int sleepCount = 0;
                while (!File.Exists(QMASTER_EXE_DIR + "cmdout.txt") && sleepCount < 150)
                {
                    Thread.Sleep(4000);
                    sleepCount++;
                }
                string cmdfileContent = "";
                if (File.Exists(QMASTER_EXE_DIR + "cmdout.txt"))
                {
                    StreamReader cmdoutFile = new StreamReader(QMASTER_EXE_DIR + "cmdout.txt");
                    cmdfileContent = cmdoutFile.ReadToEnd();
                    cmdoutFile.Close();
                }
                LogInfo("Response: " + cmdfileContent);
                if (!cmdfileContent.Contains("Done!"))
                {
                    throw new Exception("Unable to process file " + inputFile);
                }
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
            finally
            {
                if (File.Exists(outputDir + outFile))
                {
                    File.Copy(outputDir + outFile, outputFile, true);
                    File.Delete(outputDir + outFile);
                }
                if(File.Exists(inputDir+inFile))File.Delete(inputDir+inFile);
            }
        }

        private void CreateCodecInputFile(string fileName, Hashtable guidHash, QmHashTable codecSettings)
        {
            StreamWriter codecInputFile = new StreamWriter(QMASTER_EXE_DIR + fileName, false);
            LogInfo("Codec Settings");
            foreach (string currentKey in guidHash.Keys)
            {
                LogInfo(currentKey + " = " + codecSettings[currentKey].ToString());
                codecInputFile.WriteLine((string)guidHash[currentKey] + " " + codecSettings[currentKey].ToString());
            }
            codecInputFile.Close();
        }

        private string GetCodesrcFilePath(string aviRefFile)
        {
            string filesDir = QMASTER_DRIVE + "\\Video\\User Defined Files\\";
            string baseName = GetFileBaseName(aviRefFile);
            string codesrcRefFile = baseName.Replace(".avi","_codesrc.avi");
            string uncompRefFile = baseName.Replace(".avi", "_uncompref.avi");
            if (!File.Exists(filesDir + "Source Files\\" + codesrcRefFile) || !File.Exists(filesDir + "Uncompressed Reference Files\\" + uncompRefFile))
            {
                return "";
            }
            else
            {
                return filesDir + "Source Files\\" + codesrcRefFile;
            }
        }

        private void SetWrkAroundFiles(string refFile, string testFile)
        {
            this.wrkAroundFileBaseName = GetFileBaseName(refFile);
            this.wrkAroundTestFileName = testFile;
        }

        private string GetFileBaseName(string filePath)
        {
            Regex fileNameParser = new Regex("[\\/]*(?<baseName>[\\w\\.]+) *$");
            return fileNameParser.Match(filePath).Groups["baseName"].Value.Trim();
        }

        class QmHashTable : Hashtable
        {
            public void Merge(Hashtable srcHash)
            {
                foreach (DictionaryEntry currentEntry in srcHash)
                {
                    this[currentEntry.Key.ToString()] = currentEntry.Value;
                }
            }
        }
    }
}
