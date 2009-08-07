using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using System.Reflection;
using System.Threading;
using System.Text.RegularExpressions;
using DvtbHandler;

namespace DvtbHandler
{
    public class DvtbClient
    {
        private static Object socketNumLock = new Object();
        private static int videoSockets = -3;
        private static int audioSockets = -3;
        private DvtbControlSocket dvtbClient;
        private const int DEFAULT_TIMEOUT = 10000;
        private const int THREAD_WAIT = 4000;
        private ArrayList threadsArray = new ArrayList();
        private string ipAddress;
        private int port;
        private DvtbClientLogger clientLogger = null;
        private string logPath;
        private bool numSocketsSet = false;
        private int debug = -1;

        public DvtbClient(Hashtable equipmentInfo, string logPath)
        {
            try
            {
                this.ipAddress = (string)equipmentInfo["telnet_ip"];
                this.port = (int)equipmentInfo["telnet_port"];
                this.logPath = logPath;
                this.StartLogger(logPath);
                LogInfo("Dvtb Session Started");
                this.dvtbClient = new DvtbControlSocket(ipAddress, port, logPath);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw new Exception("Unable to Instantiate a dvtb client\n"+MethodInfo.GetCurrentMethod().Name+ "\n" + e.ToString());
            }
        }

        public DvtbClient(Hashtable equipmentInfo)
        {
            try
            {
                this.ipAddress = (string)equipmentInfo["telnet_ip"];
                this.port = (int)equipmentInfo["telnet_port"];
                this.dvtbClient = new DvtbControlSocket(ipAddress, port);
            }
            catch (Exception e)
            {
                throw new Exception("Unable to Instantiate a dvtb client\n" + MethodInfo.GetCurrentMethod().Name + "\n" + e.ToString());
            }
        }

        public int Debug
        {
            set{
                debug = value;
                if (debug >= 0)System.Diagnostics.Debugger.Launch();
            }
            get { return debug; }
        }

        public void SetMaxNumberOfSockets(int vidSockets, int audSockets)
        {
            videoSockets = vidSockets;
            audioSockets = audSockets;
            this.numSocketsSet = true;
        }

        public string SendCmd(string command, string response)
        {
            this.dvtbClient.DvtbcSend(DvtbControlSocket.DVTB_COMMAND, command);
            Hashtable clientResponse = this.dvtbClient.SocketExpect(response, DEFAULT_TIMEOUT);
            if (!(bool)clientResponse["expectResult"]) throw new Exception("Timedout waiting for response " + response);
            return (string)clientResponse["readResult"];
        }

        public void SendFunc(Hashtable funcParams)
        {
            try
            {
                string command = "func " + (string)funcParams["function"];
                if (funcParams.ContainsKey("Source")) command += " -s " + funcParams["Source"];
                if (funcParams.ContainsKey("Target")) command += " -t " + funcParams["Target"];
                this.dvtbClient.DvtbcSend(DvtbControlSocket.DVTB_COMMAND, command);
                Hashtable clientResponse = this.dvtbClient.SocketExpect("PNDG\x00", DEFAULT_TIMEOUT);
                if (!(bool)clientResponse["expectResult"]) throw new Exception("Timedout waiting for response func ack PNDG");
                Hashtable sockParams = new Hashtable();
                sockParams["logPath"] = this.logPath;
                sockParams["targetIndex"] = this.dvtbClient.ReadInt32();
                sockParams["ipAddress"] = this.ipAddress;
                sockParams["port"] = this.port;
                sockParams["threadType"] = funcParams["threadType"];
                Thread mediaThread = new Thread(new ParameterizedThreadStart(StartMedia));
                mediaThread.Start(sockParams);
                threadsArray.Add(mediaThread);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        public void SendVideoFunc(Hashtable funcParams)
        {
            try
            {
                if (!numSocketsSet || videoSockets == -3) throw new System.Exception("Maximum number of sockets have not been set with function SetMaxNumberOfSocket");
                lock (socketNumLock)
                {
                    videoSockets -= 1;
                }
                while (videoSockets < 0)
                {
                    Thread.Sleep(THREAD_WAIT);
                }
                funcParams["threadType"] = 0; //type for video threads
                SendFunc(funcParams);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        public void SendAudioFunc(Hashtable funcParams)
        {
            try
            {
                if (!numSocketsSet || audioSockets == -3) throw new System.Exception("Maximum number of sockets have not been set with function SetMaxNumberOfSocket");
                lock (socketNumLock)
                {
                    audioSockets -= 1;
                }
                while (audioSockets < 0)
                {
                    Thread.Sleep(THREAD_WAIT);
                }
                funcParams["threadType"] = 1; //type for audio threads
                SendFunc(funcParams);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                throw e;
            }
        }

        private static void StartMedia(object socketParams)
        {
            Hashtable mediaSocketParams = (Hashtable)socketParams;
            DvtbMediaSocket mediaSocket = new DvtbMediaSocket((string)mediaSocketParams["ipAddress"],(int)mediaSocketParams["port"], (int)mediaSocketParams["targetIndex"],(string)mediaSocketParams["logPath"]);
            mediaSocket.DvtbFileOps();
            lock (socketNumLock)
            {
                if ((int)mediaSocketParams["threadType"] == 0) videoSockets += 1;
                else if ((int)mediaSocketParams["threadType"] == 1) audioSockets += 1;
            }
        }

        public string GetParam(Hashtable dvtbParams)
        {
            if (dvtbParams.ContainsKey("Param"))
            {
                return this.SendCmd("getp " + (string)dvtbParams["Class"] + " " + (string)dvtbParams["Param"], "PASS");
            }
            else
            {
                return this.SendCmd("getp " + (string)dvtbParams["Class"], "PASS");
            }
        }

        public void SetParam(Hashtable dvtbParams)
        {
            this.SendCmd("setp " + (string)dvtbParams["Class"] + " " + (string)dvtbParams["Param"] + " " + (dvtbParams["Value"].ToString()), "PASS");
        }

        public void VideoDecoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "viddec";
                this.SendVideoFunc(funcParams);
            }
        }

        public void VideoEncoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "videnc";
                this.SendVideoFunc(funcParams);
            }
        }

        public void AudioDecoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "auddec";
                this.SendAudioFunc(funcParams);
            }
        }

        public void AudioEncoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "aaclc1dot1enc";
                this.SendAudioFunc(funcParams);
            }
        }

        public void SpeechDecoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "sphdec";
                this.SendAudioFunc(funcParams);
            }
        }

        public void SpeechEncoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "sphenc";
                this.SendAudioFunc(funcParams);
            }
        }

        public void ImageDecoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "imgdec";
                this.SendVideoFunc(funcParams);
            }
        }

        public void ImageEncoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "imgenc";
                this.SendVideoFunc(funcParams);
            }
        }

        public void VideoEncodingDecoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "videncdec";
                this.SendVideoFunc(funcParams);
            }
        }

        public void SpeechEncodingDecoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "sphencdec";
                this.SendAudioFunc(funcParams);
            }
        }

        public void AudioEncodingDecoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "audencdec";
                this.SendAudioFunc(funcParams);
            }
        }

        public void ImageEncodingDecoding(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "imgencdec";
                this.SendVideoFunc(funcParams);
            }
        }

        public void AudioCapture(Hashtable dvtbParams)
        {

            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "audio";
                this.SendAudioFunc(funcParams);
            }
        }

        public void AudioPlay(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "audio";
                this.SendAudioFunc(funcParams);
            }
        }

        public void AudioLoopback(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || audioSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "audioloop";
                this.SendAudioFunc(funcParams);
            }
        }

        public void VideoCapture(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "vpfe";
                this.SendVideoFunc(funcParams);
            }
        }

        public void VideoPlay(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "vpbe";
                this.SendVideoFunc(funcParams);
            }
        }

        public void VideoLoopback(Hashtable dvtbParams)
        {
            if ((bool)dvtbParams["mandatory"] || videoSockets > 0)
            {
                Hashtable funcParams = (Hashtable)dvtbParams.Clone();
                if (!funcParams.ContainsKey("function")) funcParams["function"] = "vidloop";
                this.SendVideoFunc(funcParams);
            }
        }

 
        public void Disconnect()
        {
            this.dvtbClient.Disconnect();
        }

        public void WaitForThreads()
        {         
            foreach( Thread mediaThread in this.threadsArray)
            {
               if(mediaThread.IsAlive) mediaThread.Join();
            }
        }

        public void StartLogger(string logPath)
        {
            this.clientLogger = new DvtbClientLogger(this.ToString(), logPath);
        }

        public void StopLogger()
        {
            if(this.clientLogger !=null)this.clientLogger.CloseLogger();
        }

        private void LogInfo(string info)
        {
            if (this.clientLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(clientLogger.LogInfo));
                logThread.Start(info);
            }
        }

        private void LogError(string error)
        {
            if (this.clientLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(clientLogger.LogError));
                logThread.Start(error);
            }
        }

        private void LogWarning(string warning)
        {
            if (this.clientLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(clientLogger.LogWarning));
                logThread.Start(warning);
            }
        }

    }
}
