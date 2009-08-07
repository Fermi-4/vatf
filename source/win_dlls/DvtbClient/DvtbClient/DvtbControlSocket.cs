using System;
using System.Collections.Generic;
using System.Collections;
using System.Threading;
using System.Text;
using System.Net.Sockets;
using System.Text.RegularExpressions;
using DvtbHandler;

namespace DvtbHandler
{
    class DvtbControlSocket : DvtbSocket
    {
        private int threadSleepInterval = 10;

        public DvtbControlSocket(string ipAddress, int port)
            : base(ipAddress, port)
        {
        }

        public DvtbControlSocket(string ipAddress, int port, string logPath)
            : base(ipAddress, port)
        {
            this.StartLogger(logPath);
        }

        public Hashtable SocketExpect(string expectString, int timeout)
        {
            Hashtable socketState = new Hashtable();
            Hashtable result = new Hashtable();
            socketState["match"] = expectString;
            socketState["socketStream"] = this.GetStream();
            Thread readStringThread = new Thread(new ParameterizedThreadStart(SocketExpectString));
            readStringThread.Start(socketState);
            int expectCounter = 0;
            int expectTimeoutCount = (int)Math.Ceiling((float)(timeout / this.threadSleepInterval));
            while (readStringThread.IsAlive && expectCounter < expectTimeoutCount)
            {
                Thread.Sleep(this.threadSleepInterval);
                expectCounter++;
            }
            if (readStringThread.IsAlive)
            {
                readStringThread.Abort();
            }
            readStringThread.Join();
            result["readResult"] = socketState["readResult"];
            LogInfo("Target: " + (string)result["readResult"]);
            result["expectResult"] = !socketState.ContainsKey("exception");
            return result;
        }

        public Hashtable SocketExpect(byte expectByte, int timeout)
        {
            Hashtable socketState = new Hashtable();
            Hashtable result = new Hashtable();
            socketState["match"] = expectByte;
            socketState["socketStream"] = this.GetStream();
            Thread readBytesThread = new Thread(new ParameterizedThreadStart(SocketExpectByte));
            readBytesThread.Start(socketState);
            int expectCounter = 0;
            int expectTimeoutCount = (int)Math.Ceiling((float)(timeout / this.threadSleepInterval));
            while (readBytesThread.IsAlive && expectCounter < expectTimeoutCount)
            {
                Thread.Sleep(this.threadSleepInterval);
                expectCounter++;
            }
            if (readBytesThread.IsAlive)
            {
                readBytesThread.Abort();
            }
            readBytesThread.Join();
            result["readResult"] = socketState["readResult"];
            LogInfo("Target: " + result["readResult"].ToString());
            result["expectResult"] = !socketState.ContainsKey("exception");
            return result;
        }

        public new void StartLogger(string logPath)
        {
            this.clientLogger = new DvtbClientLogger(this.ToString(), logPath);
        }

        public new void Disconnect()
        {
            this.DvtbcSend(DVTB_RECON);
            this.mediaStream.Close();
        }

        protected static void SocketExpectString(object socketState)
        {
            Hashtable expectSocketState = (Hashtable)socketState;
            Regex expectExpression = new Regex((string)expectSocketState["match"]);
            byte[] myReadBuffer = new byte[1];
            StringBuilder myCompleteMessage = new StringBuilder();
            int numberOfBytesRead = 0;
            try
            {
                NetworkStream socketStream = (NetworkStream)expectSocketState["socketStream"];
                do
                {
                    numberOfBytesRead = socketStream.Read(myReadBuffer, 0, myReadBuffer.Length);

                    myCompleteMessage.AppendFormat("{0}", Encoding.ASCII.GetString(myReadBuffer, 0, numberOfBytesRead));

                }
                while (!expectExpression.Match(myCompleteMessage.ToString()).Success);
            }
            catch (Exception e)
            {
                expectSocketState["exception"] = e.ToString();
            }
            finally
            {
                expectSocketState["readResult"] = myCompleteMessage.ToString();
            }

        }

        protected static void SocketExpectByte(object socketState)
        {
            Hashtable expectSocketState = (Hashtable)socketState;
            ArrayList byteMessage = new ArrayList();
            int numberOfBytesRead;
            byte[] myReadBuffer = new byte[1];

            try
            {
                NetworkStream socketStream = (NetworkStream)expectSocketState["socketStream"];
                do
                {
                    numberOfBytesRead = socketStream.Read(myReadBuffer, 0, myReadBuffer.Length);
                    byteMessage.Add(myReadBuffer[0]);
                }
                while (myReadBuffer[0] != (byte)expectSocketState["match"]);
            }
            catch (Exception e)
            {
                expectSocketState["exception"] = e.ToString();
            }
            finally
            {
                expectSocketState["readResult"] = byteMessage;
            }
        }
    }
}
