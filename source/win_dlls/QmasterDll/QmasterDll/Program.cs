using System;
using System.Collections.Generic;
using System.Collections;
using System.Text;
using System.IO;
using TeHandlers;

namespace TeHandlers
{
    public sealed class Program
    {
        [STAThread]
        static void Main()
        {
            for (int iter = 0; iter < 100; iter++)
            {
                System.Console.WriteLine("Qmaster driver tester iteration " + iter.ToString());
                bool calFlag = false;
                if (iter == 0) calFlag = true;
                Hashtable eInfo = new Hashtable();
                if (File.Exists("C:\\qm_dll_tester.txt")) File.Delete("C:\\qm_dll_tester.txt");
                eInfo["telnet_ip"] = "10.0.0.20";
                QmasterDllDriver tester = new QmasterDllDriver(eInfo, "C:\\qm_dll_log.txt");
                
                if (calFlag)
                {
                    System.Console.WriteLine("Calibrating Q-Master");
                    Hashtable calInfo = new Hashtable();
                    calInfo["is_pal"] = false;
                    string[] refFiles = new string[2] { "football_704x480_420p_150frames_30fps.avi", "sheilds_720x480_420p_252frames_30fps.avi" };
                    foreach (string refFile in refFiles)
                    {
                        calInfo["ref_file"] = refFile;
                        tester.Calibrate(calInfo);
                    }
                }

                System.Console.WriteLine("Composite out to composite in test");
                tester.CompositeOutToCompositeInTest("sheilds_720x480_420p_252frames_30fps.avi", "a_qm_driver_dll_test.avi", false);
                if (tester.WaitForAnalogTestAck(120000) != 0)
                {
                    tester.QmAbort();
                }
                else
                {
                    Program.SaveScores(tester);
                }

                System.Console.WriteLine("File to File Test");
                tester.FileToFileTest("C:\\Video_tools\\cablenews_320x240_420p_511frames_768000bps_test.avi", "C:\\Video_tools\\cablenews_320x240_420p_511frames_768000bps_test.avi", false);
                Program.SaveScores(tester);

                System.Console.WriteLine("H264 Encode File Test");
                Hashtable encSettings = new Hashtable();
                encSettings["video_format"] = 2;
                encSettings["enc_avg_bitrate"] = 768000;
                encSettings["enc_max_bitrate"] = 820000;
                tester.H264EncodeFile("C:\\Video_tools\\cablenews_320x240_420p_511frames.avi", "C:\\Video_tools\\cablenews_320x240_420p_511frames_qm_dll.264", encSettings);

                System.Console.WriteLine("MPEG4 Encode File Test");
                tester.Mpeg4EncodeFile("C:\\Video_tools\\cablenews_320x240_420p_511frames.avi", "C:\\Video_tools\\cablenews_320x240_420p_511frames_qm_dll.mpeg4", new Hashtable());

                System.Console.WriteLine("H264 Decode File Test");
                tester.H264DecodeFile("C:\\Video_tools\\cablenews_320x240_420p_511frames_768000bps.264", "C:\\Video_tools\\cablenews_320x240_420p_511frames_768000bps_qm_dll_264.yuv", new Hashtable());

                System.Console.WriteLine("MPEG4 Decode File Test");
                Hashtable decSettings = new Hashtable();
                decSettings["dec_post_processing"] = 1;
                tester.Mpeg4DecodeFile("C:\\Video_tools\\cablenews_320x240_420p_511frames_768000bps.mpeg4", "C:\\Video_tools\\cablenews_320x240_420p_511frames_768000bps_qm_dll_mpeg4.yuv", decSettings);

                System.Console.WriteLine("H264 Codecsrc Encoded File Test");
                tester.GetCodesrcH264EncodedFile("football_704x480_420p_150frames_30fps.avi", "C:\\Video_tools\\codesrc_football_704x480_420p_150frames_30fps_qm_dll.264", new Hashtable());

                System.Console.WriteLine("MPEG4 Codesrc Encoded File Test");
                tester.GetCodesrcH264EncodedFile("sheilds_720x480_420p_252frames_30fps.avi", "C:\\Video_tools\\codesrc_sheilds_720x480_420p_252frames_30fps_qm_dll.mpeg4", new Hashtable());
                
                tester.EndSession();
            }
        }

        private static void SaveScores(QmasterDllDriver tester)
        {
            StreamWriter resultFile = new StreamWriter("C:\\qm_dll_tester.txt",true);
            resultFile.WriteLine("==================Mean MOS Score====================");
            resultFile.WriteLine(tester.GetMosScore());
            resultFile.WriteLine("=================Frames PSNR Scores=================");
            foreach (double score in tester.GetPsnrScores())
            {
                resultFile.WriteLine(score);
            }
            resultFile.WriteLine("================Mean PSNR Score=======================");
            resultFile.WriteLine(tester.GetPsnrScore());
            resultFile.WriteLine("======================Frame 10 PSNR Score===================");
            resultFile.WriteLine(tester.GetPsnrScore(10));

            resultFile.WriteLine("====================Frames Blurring Scores========================");
            foreach (double score in tester.GetBlurringScores())
            {
                resultFile.WriteLine(score);
            }
            resultFile.WriteLine("===========================Mean Blurring Score============================");
            resultFile.WriteLine(tester.GetBlurringScore());
            resultFile.WriteLine("==========================Frame 10 Blurring Score==========================");
            resultFile.WriteLine(tester.GetBlurringScore(10));

            resultFile.WriteLine("====================Frames Blocking Scores========================");
            foreach (double score in tester.GetBlockingScores())
            {
                resultFile.WriteLine(score);
            }
            resultFile.WriteLine("===========================Mean Blocking Score============================");
            resultFile.WriteLine(tester.GetBlockingScore());
            resultFile.WriteLine("==============================Frame 10 Blocking Score===========================");
            resultFile.WriteLine(tester.GetBlockingScore(10));

            resultFile.WriteLine("====================Frames Losts Scores========================");
            foreach (double score in tester.GetFramesLostCount())
            {
                resultFile.WriteLine(score);
            }
            resultFile.WriteLine("===========================Total Frames Losts Score============================");
            resultFile.WriteLine(tester.GetFrameLostCount());
            resultFile.WriteLine("==============================Frame 10 Frames Losts Score===========================");
            resultFile.WriteLine(tester.GetFrameLostCount(10));

            resultFile.WriteLine("===========================Mean Jerkiness Score============================");
            resultFile.WriteLine(tester.GetJerkinessScore());

            resultFile.WriteLine("===========================Mean Level Score============================");
            resultFile.WriteLine(tester.GetLevelScore());

            resultFile.WriteLine("===========================Mean Jitter Score============================");
            resultFile.WriteLine(tester.GetJitterScore());
            resultFile.Close();
        }
    }
}
