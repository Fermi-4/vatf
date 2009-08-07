using System;
using System.Collections.Generic;
using System.Collections;
using System.Text;
using System.IO;
using System.Reflection;
using DvtbHandler;

namespace DvtbHandler
{
    class DvtbMediaSocket : DvtbSocket
    {

        private ArrayList mediaFiles = new ArrayList();


        public DvtbMediaSocket(string ipAddress, int port, int targetIndex)
            : base(ipAddress, port)
        {
            this.mediaFiles.Add(null);
            this.DvtbcSend(targetIndex);
        }

        public DvtbMediaSocket(string ipAddress, int port, int targetIndex, string logPath)
            : base(ipAddress, port)
        {
            this.mediaFiles.Add(null);
            this.StartLogger(logPath);
            this.DvtbcSend(targetIndex);
        }

        public new void StartLogger(string logPath)
        {
            this.clientLogger = new DvtbClientLogger(this.ToString()+DateTime.Now.Ticks.ToString(), logPath);
        }

        public void DvtbFileOps()
        {

            int result = DVTB_FAIL;

            byte[] dvtbHeader = new byte[1];

            try
            {
                do
                {
                    this.mediaStream.Read(dvtbHeader, 0, dvtbHeader.Length);
                    switch (dvtbHeader[0])
                    {
                        case DVTB_RESPONSE:
                            string data = DvtbcReadData();
                            data += DvtbcReadData();
                            LogInfo("Target: " + data);
                            break;
                        case DVTB_ERROR:
                            result = DvtbcError();
                            break;
                        case DVTB_LOG:
                            result = DvtbcLog();
                            break;
                        case DVTB_DEBUG:
                            result = DvtbcDebug();
                            break;
                        case DVTB_FOPEN:
                            result = DvtbcFOpen();
                            break;
                        case DVTB_FREAD:
                            result = DvtbcFRead();
                            break;
                        case DVTB_FWRITE:
                            result = DvtbcFWrite();
                            break;
                        case DVTB_FSEEK:
                            result = DvtbcFSeek();
                            break;
                        case DVTB_FTELL:
                            result = DvtbcFTell();
                            break;
                        case DVTB_FCLOSE:
                            result = DvtbcFClose();
                            break;
                        case DVTB_FEOF:
                            result = DvtbcFEOF();
                            break;
                        case DVTB_SOC_CLOSE:
                            DvtbcFreeSocket();
                            return;
                        default:
                            throw new Exception("Invalid Command " + dvtbHeader[0].ToString() + " for file operations");
                    }
                } while (result != DVTB_FAIL);
            }
            catch (Exception e)
            {
                throw e;
            }
            finally
            {
                if (this.Connected) this.mediaStream.Close();
            }

        }

        private int DvtbcError()
        {
            try
            {
                string error = DvtbcReadData();
                error += DvtbcReadData();
                LogInfo("Target: " + error);
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                return DVTB_FAIL;
            }
            return DVTB_SUCCESS;
        }

        private int DvtbcLog()
        {
            try
            {
                string log = DvtbcReadData();
                LogInfo(log);
                return DVTB_SUCCESS;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                return DVTB_FAIL;
            }
        }

        private int DvtbcDebug()
        {
            try
            {
                string debug = DvtbcReadData();
                LogDebug(debug);
                return DVTB_SUCCESS;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                return DVTB_FAIL;
            }
        }

        private int DvtbcFOpen()
        {
            try
            {
                string filePath = this.DvtbcReadData().Trim(new char[] { '\x00' });
                string fileMode = this.DvtbcReadData().Trim(new char[] { '\x00' });
                LogInfo("Target: Open " + filePath + " in mode " + fileMode);
                if (fileMode.Contains("rb"))
                {
                    this.mediaFiles.Add(new FileStream(filePath, FileMode.Open, FileAccess.Read));
                }
                else
                {
                    this.mediaFiles.Add(new FileStream(filePath, FileMode.Create, FileAccess.Write));
                }
                this.DvtbcSend(DVTB_RESPONSE,this.mediaFiles.Count-1);
                return DVTB_SUCCESS;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                return DVTB_FAIL;
            }
        }

        private int DvtbcFWrite()
        {
            int fileDescriptor = -1;
            try
            {
                fileDescriptor = ReadInt32();
                int dataSize = ReadInt32();
                LogInfo("Target: Write " + dataSize.ToString() + " bytes to file " + fileDescriptor.ToString());
                byte[] data = new byte[dataSize];
                int bytesRead = 0;
                while (bytesRead != dataSize)
                {
                    bytesRead += this.mediaStream.Read(data, bytesRead, dataSize-bytesRead);
                }
                ((FileStream)this.mediaFiles[fileDescriptor]).Write(data, 0, dataSize);
  //              this.DvtbcSend(DVTB_DATA, fileDescriptor);       //Commented out to comply with new dvtb
   //             this.DvtbcSend(bytesRead);                      //Commented out to comply with new dvtb
                return DVTB_SUCCESS;
            }
            catch (Exception e)
            {
                this.DvtbcSend(DVTB_ERROR, fileDescriptor);
                this.LogError(e.ToString());
                return DVTB_FAIL;
            }
        }

        private int DvtbcFRead()
        {
            int fileDescriptor = -1;
            try
            {
                fileDescriptor = ReadInt32();
                int dataSize = ReadInt32();
                LogInfo("Target: Read " + dataSize.ToString() + " bytes from file " + fileDescriptor.ToString());
                byte[] data = new byte[dataSize];
                int bytesRead = ((FileStream)this.mediaFiles[fileDescriptor]).Read(data, 0, dataSize);
                if (bytesRead == 0)
                {
                    this.DvtbcSend(DVTB_ERROR, fileDescriptor);
                }
                else
                {
                    if (bytesRead < dataSize)
                    {
                        byte[] lastData = new byte[bytesRead];
                        Array.Copy(data, lastData, bytesRead);
                        data = lastData;
                    }
                    this.DvtbcSend(DVTB_DATA, fileDescriptor);
                    this.DvtbcSendData(data);
                }
            }
            catch (Exception e)
            {
                this.DvtbcSend(DVTB_ERROR, fileDescriptor);
                LogError(e.ToString());
            }
            return DVTB_SUCCESS;
        }

        private void DvtbcSendData(byte[] msg)
        {
            byte[] data = new byte[msg.Length + 4];
            BitConverter.GetBytes(msg.Length).CopyTo(data, 0);
            msg.CopyTo(data, 4);
//            LogInfo("Host: "+BitConverter.ToString(data));
            this.SendMsg(data);
        }

        private int DvtbcFTell()
        {
            int fileDescriptor = this.ReadInt32();
            LogInfo("Target: File " + fileDescriptor.ToString() + " position?");
            int filePosition = (int)((FileStream)this.mediaFiles[fileDescriptor]).Position;
 //           LogInfo("Host: File " + fileDescriptor.ToString() + " at "+ filePosition.ToString());
            this.DvtbcSend(DVTB_RESPONSE, fileDescriptor);
            this.DvtbcSend(filePosition);

            return DVTB_SUCCESS;
        }

        private int DvtbcFClose()
        {
            try
            {
                int fileDescriptor = this.ReadInt32();
                LogInfo("Target: Close file " + fileDescriptor.ToString());
                if (this.mediaFiles[fileDescriptor] != null) ((FileStream)this.mediaFiles[fileDescriptor]).Close();
                this.DvtbcSend(DVTB_RESPONSE, fileDescriptor);
                this.mediaFiles[fileDescriptor] = null;
                return DVTB_SUCCESS;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                this.DvtbcSend(DVTB_ERROR);
                return DVTB_FAIL;
            }
        }

        private int DvtbcFEOF()
        {
            try
            {
                int fileDescriptor = ReadInt32();
                LogInfo("Target: EOF for file " + fileDescriptor.ToString() + "?");
                int fileEof = 0;
                if (((FileStream)this.mediaFiles[fileDescriptor]).Length < ((FileStream)this.mediaFiles[fileDescriptor]).Position) fileEof = 4;
                this.DvtbcSend(DVTB_RESPONSE, fileDescriptor);
                this.DvtbcSend(fileEof);
                return DVTB_SUCCESS;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                this.DvtbcSend(DVTB_ERROR);
                return DVTB_FAIL;
            }
        }

        private int DvtbcFSeek()
        {
            try
            {
                int fileDescriptor = this.ReadInt32();
                int offset = this.ReadInt32();
                int whence = this.ReadInt32();
                LogInfo("Target: File " + fileDescriptor.ToString() + " seek " + offset.ToString() + " from " + whence.ToString());
                ((FileStream)this.mediaFiles[fileDescriptor]).Seek((long)offset, (SeekOrigin)whence);
                this.DvtbcSend(DVTB_RESPONSE, fileDescriptor);
                return DVTB_SUCCESS;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                this.DvtbcSend(DVTB_ERROR);
                return DVTB_FAIL;
            }
        }

        private int DvtbcFreeSocket()
        {
            try
            {
                this.mediaStream.Close();
                return DVTB_SUCCESS;
            }
            catch (Exception e)
            {
                LogError(e.ToString());
                this.DvtbcSend(DVTB_ERROR);
                return DVTB_FAIL;
            }
        }

        private string DvtbcReadData()
        {
            int dataSize = ReadInt32();
            byte[] stringArray = new byte[dataSize];
            int bytesRead = 0;
            while (bytesRead < dataSize)
            {
                bytesRead += this.mediaStream.Read(stringArray, bytesRead, stringArray.Length-bytesRead);
            }
            return Encoding.ASCII.GetString(stringArray, 0, dataSize);
        }

        private string DvtbcReadData(int dataSize)
        {
            byte[] stringArray = new byte[dataSize];
            int bytesRead = 0;
            while (bytesRead < dataSize)
            {
                bytesRead += this.mediaStream.Read(stringArray, bytesRead, stringArray.Length-bytesRead);
            }
            return BitConverter.ToString(stringArray);
        }
    }
}
