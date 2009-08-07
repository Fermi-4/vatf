using System;
using System.Collections.Generic;
using System.Text;
using System.Net.Sockets;
using System.Threading;
using System.IO;
using DvtbHandler;

namespace DvtbHandler
{
    class DvtbSocket : TcpClient
    {
        public const byte DVTB_INVALID = (byte)0x0;
        public const byte DVTB_COMMAND = (byte)0xC0;
        public const byte DVTB_RESPONSE = (byte)0xA0;
        public const byte DVTB_ASYNC_RESPONSE = (byte)0xA1;
        public const byte DVTB_SOC_CLOSE = (byte)0xA2;
        public const byte DVTB_RECON = (byte)0xA3;
        public const byte DVTB_DATA = (byte)0xD0;
        public const byte DVTB_ERROR = (byte)0xE0;
        public const byte DVTB_LOG = (byte)0xE1;
        public const byte DVTB_DEBUG = (byte)0xE2;
        public const byte DVTB_FOPEN = (byte)0xF0;
        public const byte DVTB_FREAD = (byte)0xF1;
        public const byte DVTB_FWRITE = (byte)0xF2;
        public const byte DVTB_FSEEK = (byte)0xF3;
        public const byte DVTB_FTELL = (byte)0xF4;
        public const byte DVTB_FCLOSE = (byte)0xF5;
        public const byte DVTB_FEOF = (byte)0xF6;
        public const int DVTB_FAIL = -1;
        public const int DVTB_SUCCESS = 0;
        protected DvtbClientLogger clientLogger = null;
        protected NetworkStream mediaStream;

        public DvtbSocket(string IpAddress, int port)
        {
            this.Connect(IpAddress, port);
            this.mediaStream = this.GetStream();
        }

        public void DvtbcSend(int number)
        {
            byte[] byteArray = BitConverter.GetBytes(number);
     //       if(!BitConverter.IsLittleEndian)Array.Reverse(byteArray);
            SendMsg(byteArray);
        }

        public void DvtbcSend(byte header)
        {
            byte[] data = new byte[] { header };
            SendMsg(data);
        }

        public void DvtbcSend(string message)
        {
            Encoding encoding = Encoding.ASCII;
            LogInfo("Host: " + message);
            byte[] msg = encoding.GetBytes(message);
            byte[] data = new byte[msg.Length + 5];
            BitConverter.GetBytes(msg.Length + 1).CopyTo(data, 0);
            msg.CopyTo(data, 4);
            data[data.Length - 1] = (byte)0;
            this.SendMsg(data);
        }

        public void DvtbcSend(byte header, int number)
        {
            this.DvtbcSend(header);
            this.DvtbcSend(number);
        }

        public void DvtbcSend(byte header, string message)
        {
            this.DvtbcSend(header);
            this.DvtbcSend(message);
        }

        public int ReadInt32()
        {
            byte[] int32Array = new byte[4];
            int bytesRead = 0;
            while (bytesRead != 4)
            {
                bytesRead += this.mediaStream.Read(int32Array, bytesRead, 4-bytesRead);
            }
            return BitConverter.ToInt32(int32Array, 0);
        }

        public void Disconnect()
        {
            this.mediaStream.Close();
        }

        public void StartLogger(string logPath)
        {
            this.clientLogger = new DvtbClientLogger(this.ToString(), logPath);
        }

        public void StopLogger()
        {
            if (this.clientLogger != null) this.clientLogger.CloseLogger();
        }

        protected void LogInfo(string info)
        {
            if (this.clientLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(clientLogger.LogInfo));
                logThread.Start(info);
            }
        }

        protected void LogError(string error)
        {
            if (this.clientLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(clientLogger.LogError));
                logThread.Start(error);
            }
        }

        protected void LogWarning(string warning)
        {
            if (this.clientLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(clientLogger.LogWarning));
                logThread.Start(warning);
            }
        }

        protected void LogDebug(string debug)
        {
            if (this.clientLogger != null)
            {
                Thread logThread = new Thread(new ParameterizedThreadStart(clientLogger.LogDebug));
                logThread.Start(debug);
            }
        }

        protected void SendMsg(byte[] data)
        {
            this.GetStream().Write(data, 0, data.Length);
        }
    }
}
