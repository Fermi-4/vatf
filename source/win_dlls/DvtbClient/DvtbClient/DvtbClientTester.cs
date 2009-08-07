using System;
using System.Collections.Generic;
using System.Collections;
using System.Text;
using DvtbHandler;
using System.IO;

namespace DvtbHandler
{
    public sealed class DvtbClientTester
    {
        private DvtbClientTester() { }

        [STAThread]
        static int Main()
        {
            for (int i = 0; i < 2; i++)
            {
                System.Console.WriteLine("Test Started");
                Hashtable equipInfo = new Hashtable();
                equipInfo.Add("telnet_ip", "10.218.111.108");
                equipInfo.Add("telnet_port", 5000);
                DvtbClient myDvtbClient = new DvtbClient(equipInfo, "C:\\c_sharp_client_"+i.ToString()+".txt");
                myDvtbClient.SetMaxNumberOfSockets(3,1);
                try
                {
                    Hashtable paramHash = new Hashtable();
                    paramHash["Class"] = "vpbe";
                    paramHash["Param"] = "width";
                    paramHash["Value"] = "320";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "vpbe";
                    paramHash["Param"] = "height";
                    paramHash["Value"] = "240";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "vpfe";
                    paramHash["Param"] = "width";
                    paramHash["Value"] = "320";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "vpfe";
                    paramHash["Param"] = "height";
                    paramHash["Value"] = "240";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "videnc";
                    paramHash["Param"] = "codec";
                    paramHash["Value"] = "mpeg4enc";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "videnc";
                    paramHash["Param"] = "numframes";
                    paramHash["Value"] = "1800";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "viddec";
                    paramHash["Param"] = "maxFrameRate";
                    paramHash["Value"] = "30000";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "viddec";
                    paramHash["Param"] = "maxBitRate";
                    paramHash["Value"] = "10000000";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "viddec";
                    paramHash["Param"] = "displayWidth";
                    paramHash["Value"] = "0";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "viddec";
                    paramHash["Param"] = "codec";
                    paramHash["Value"] = "mpeg4dec";
                    myDvtbClient.SetParam(paramHash);
                    paramHash["Class"] = "viddec";
                    paramHash["Param"] = "codec";
                    System.Console.WriteLine(myDvtbClient.GetParam(paramHash));
                    paramHash["Class"] = "viddec";
                    paramHash["Param"] = "codec";
                    System.Console.WriteLine(myDvtbClient.GetParam(paramHash));
                    paramHash["Class"] = "viddec";
                    paramHash.Remove("Param");
                    System.Console.WriteLine(myDvtbClient.GetParam(paramHash));
                    if (i == 0)
                    {
                        Hashtable funcParams = new Hashtable();
                        funcParams["mandatory"] = true;
                        funcParams["Source"] = "C:\\Video_Tools\\cablenews_320x240_420p_511frames_768000bps.mpeg4";
                        myDvtbClient.VideoDecoding(funcParams);
                        funcParams["Target"] = "C:\\Video_Tools\\cablenews_320x240_420p_511frames_test.yuv";
                        myDvtbClient.VideoDecoding(funcParams);
                    }
                    else
                    {
                        Hashtable vidParam = new Hashtable();
                        Hashtable audParam = new Hashtable();
                        vidParam["mandatory"] = true;
                        audParam["mandatory"] = false;
                        myDvtbClient.AudioEncodingDecoding(audParam);
                        myDvtbClient.VideoEncodingDecoding(vidParam);
                        paramHash["Class"] = "vpfe";
                        paramHash["Param"] = "chanNumber";
                        paramHash["Value"] = "1";
                        myDvtbClient.SetParam(paramHash);
                        vidParam["Target"] = "C:\\Video_tools\\dvtb_dll_client_test.mpeg4";
                        audParam["Target"] = "C:\\Video_tools\\dvtb_dll_client_test.pcm";
                        myDvtbClient.AudioEncoding(audParam);
                        myDvtbClient.VideoEncoding(vidParam);
                    }
                    myDvtbClient.WaitForThreads();
                }
                catch (Exception e)
                {
                    System.Console.WriteLine(e.ToString());
                }
                finally
                {
                    myDvtbClient.Disconnect();
                    myDvtbClient.StopLogger();
                    System.Console.WriteLine("Test Done");
                    System.Console.ReadLine();
                }
            }
            return 0;
        }
    }

    
}
