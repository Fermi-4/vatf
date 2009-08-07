using System;
using System.Collections.Generic;
using System.Text;
using log4net.Appender;
using log4net.Core;
using log4net.Layout;
using log4net;
using log4net.Filter;

namespace TeHandlers
{
    class QmasterLogger
    {
        private ILog logger;
        private static FileAppender logFileWriter = null;
        private static Object synchObject = new Object();
        private static IFilter currentFilter;

        public QmasterLogger(string classType, string logPath)
        {
            logger = LogManager.GetLogger(classType);
            lock (synchObject)
            {
                if (logFileWriter == null)
                {

                    logFileWriter = new FileAppender();
                    logFileWriter.Name = "fileLogger";
                    logFileWriter.File = logPath;
                    logFileWriter.Layout = new PatternLayout("- %date{HH:mm:ss} [%level] %logger %message%newline");
                    logFileWriter.AppendToFile = false;
                    LoggerMatchFilter loggerFilter = new LoggerMatchFilter();
                    loggerFilter.LoggerToMatch = classType;
                    loggerFilter.AcceptOnMatch = true;
                    logFileWriter.AddFilter(loggerFilter);
                    currentFilter = loggerFilter;
                    loggerFilter.Next = new DenyAllFilter();
                    logFileWriter.ActivateOptions();
                    log4net.Config.BasicConfigurator.Configure(logFileWriter);
                }
                else
                {
                    LoggerMatchFilter loggerFilter = new LoggerMatchFilter();
                    loggerFilter.LoggerToMatch = classType;
                    loggerFilter.AcceptOnMatch = true;
                    loggerFilter.Next = currentFilter.Next;
                    currentFilter.Next = loggerFilter;
                    currentFilter = loggerFilter;
                    loggerFilter.ActivateOptions();
                }
            }
        }

        public void LogWarning(object warning)
        {
            lock (synchObject)
            {
                logger.Warn(warning);
            }
        }

        public void LogError(object error)
        {
            lock (synchObject)
            {
                logger.Error(error);
            }
        }

        public void LogInfo(object info)
        {
            lock (synchObject)
            {
                logger.Info(info);
            }
        }

        public void LogDebug(object debug)
        {
            lock (synchObject)
            {
                logger.Debug(debug);
            }
        }

        public void CloseLogger()
        {
            try
            {
                logFileWriter.Close();
                LogManager.Shutdown();
            }
            finally
            {
                logFileWriter = null;
            }
        }
    }
}
