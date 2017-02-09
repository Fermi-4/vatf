load(java.lang.System.getenv("AUTO_ENV_ARGS"));
/**
 * @main.js - This script mimics Texas Instruments' load6x stand-alone
 * simulator base functionality but will work with any TI target (HW or
 * Simulator) that is supported by Debug Server Scripting.
 */

// Run loadti.
testEnv = {};
run();

/**
 * Send message to the console and log (if logging is enabled)
 * @param {String} The string to output to the console/log.
 */
function printTrace(string)
{
    if (!testEnv.quietMode)
    {
        dssScriptEnv.traceWrite(string);
    }
}

/**
 * Get error code from the given exception.
 * @param {exception} The exception from which to get the error code.
 */
function getErrorCode(exception)
{
    var ex2 = exception.javaException;
    if (ex2 instanceof Packages.com.ti.ccstudio.scripting.environment.ScriptingException) {
        return ex2.getErrorID();
    }
    return 0;
}

/**
 * This function is called to perform some clean up before exiting (or
 * aborting) the script. It assumes that the the scripting environment and
 * debug and profile servers have been created.
 */
function quit(retVal)
{

    if (isDebugSession)
    {
        // Close debug session.
        for (var core = 0; core < dsArray.length; core++) {
            dsArray[core].terminate();
        }
    }

    if (isDebugServer)
    {
        debugServer.stop();
    }

    date = new Date();
    printTrace("\nEND: " + date.toTimeString());

    if (testEnv.logFile != null)
    {
        // Close log.
        dssScriptEnv.traceEnd();
    }

    delete testEnv;

    // Terminate JVM and return main return value.
    java.lang.System.exit(retVal);
}

/*
 * Main function.
 */
function run()
{
    var inst;

    var errCode = 0;
    var retVal = 0;
    var date = 0;
    var defaultTimeout = -1;

    isDebugServer = false;
    isDebugSession = false;

    load(java.lang.System.getenv("LOADTI_PATH") + "/getArgs.js");

    getArgs();

    // Create base scripting environment.
    dssScriptEnv = Packages.com.ti.ccstudio.scripting.environment.ScriptingEnvironment.instance();

    // Set overall script timeout value.
    dssScriptEnv.setScriptTimeout(defaultTimeout);

    // Enable logging to a file if specified.
    if (testEnv.logFile != null)
    {
        // NOTE: Log output folder must already exist.
        try
        {
            dssScriptEnv.traceBegin(testEnv.logFile, java.lang.System.getenv("LOADTI_PATH").replace("\\", "/") +
                    "/DefaultStylesheet.xsl");
            dssScriptEnv.traceSetFileLevel(Packages.com.ti.ccstudio.scripting.environment.TraceLevel.ALL);
        }
        catch (ex)
        {
            errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", failed to enable logging for " + testEnv.logFile +
                    "\nLogging disabled!");
            testEnv.logFile = null;
        }
    }

    // Set console verbosity.
    if (testEnv.verboseMode)
    {
        dssScriptEnv.traceSetConsoleLevel(Packages.com.ti.ccstudio.scripting.environment.TraceLevel.ALL);
    }

    printTrace("\n***** DSS Generic Loader *****\n");

    date = new Date();
    printTrace("START: " + date.toTimeString() + "\n");

    n = 0;
          while (n < testEnv.argvArgs.length)
          {
              printTrace("testEnv.argvArgs[" + n + "] = " + testEnv.argvArgs[n]);
              n++;
          }

    // Configure the Debug Server.
    if (autotestEnv.ccsConfig != null)
    {
        printTrace("Configuring Debug Server for specified target...");

        load(java.lang.System.getenv("LOADTI_PATH") + "/dsSetup.js");

        errCode = configureDebugServer(autotestEnv.ccsConfig, dssScriptEnv);
        if (errCode != 0)
        {
            quit(errCode);
        }

        printTrace("Done");

        // There's no more to do if no outfiles have been provided.
        if (autotestEnv.outFile == null
            || ((autotestEnv.outFile.length != autotestEnv.ccsCpu.length)
               && (autotestEnv.outFile.length != 1)))
        {
            printTrace("#outFiles: " + autotestEnv.outFile.length +"; #ccsCpu: " +  autotestEnv.ccsCpu.length + ";")
            if (testEnv.outFiles != null)
            {
                printTrace("Please provide out files in getAutoArgs.js")
            }
            printTrace("Different number of cores and out files. . . Aborting");
            quit(0);
        }
    }
    else
    {
        if (java.lang.System.getProperty("os.name").contains("Linux"))
        {
            dssScriptEnv.traceWrite("No target setup configuration file specified. Aborting!");
            quit(1);
        }

        printTrace("No target setup configuration file specified. Using existing setup");
    }

    // Open Debug Server session.
    if (!isDebugServer)
    {
        debugServer = dssScriptEnv.getServer("DebugServer.1");
        isDebugServer = true;
    }

      dsArray = new Array();
    if (autotestEnv.resetSystem)
    {
        printTrace("Resetting system...");
		//Open session before reset
		dsArray[0] = debugServer.openSession(autotestEnv.ccsPlatform, autotestEnv.ccsCpu[0]);
        try
		{
			dsArray[0].expression.evaluate('GEL_AdvancedReset("System Reset")');
			wait(5000);
		}
		catch (ex)
		{
			errCode = getErrorCode(ex);
			dssScriptEnv.traceWrite("Error code #" + errCode + ", could not reset system!\nAborting!");
			// Currently reset is showing failure code -1. But reset itself succeeds. Need to follow up with CCS
			// quit(errCode != 0 ? errCode : 1);
		}
		// Close session after reset, so that reset is standalone. Session will be opened again later
		dsArray[0].terminate();
		printTrace("Resetting system complete...");
    }

      for (var core = 0; core < autotestEnv.ccsCpu.length; core++) { //open for loop
       printTrace("Connecting to: " + autotestEnv.ccsCpu[core]);
       dsArray[core] = debugServer.openSession(autotestEnv.ccsPlatform, autotestEnv.ccsCpu[core]);
          if (autotestEnv.gelFile)
          {
          printTrace("Loading GEL file...");

          // Load GEL file
          try
          {
            var loadexpr = "GEL_LoadGel(\"" + autotestEnv.gelFile + "\")";
            dsArray[core].expression.evaluate(loadexpr);
          }
          catch (ex)
          {
            errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", could not load gel file!\nAborting!");
            quit(errCode != 0 ? errCode : 1);
          }
          }

      isDebugSession = true;

      printTrace("TARGET: " + dsArray[0].getBoardName());
      //Disable auto run to main, needed for IPC
      dsArray[core].options.setBoolean("AutoRunToLabelOnRestart",false);
      //Disable software breakpoints, needed for IPC
      dsArray[core].options.setBoolean("EnableSoftwareBreakpoints",false);
    //Set the default File IO folder
    dsArray[core].options.setString("FileIODefaultDirectory", testEnv.fileIOFolder);

    printTrace("Connecting to target...");

    // Set script timeout value for connect API.
    dssScriptEnv.setScriptTimeout(testEnv.timeoutValue);

    // Connect to target. If target is simulator or already connected, a warning will be reported.
    try
    {
        dsArray[core].target.connect();
    }
    catch (ex)
    {
        errCode = getErrorCode(ex);
        dssScriptEnv.traceWrite("Error code #" + errCode + ", could not connect to target!\nAborting!");
        quit(errCode != 0 ? errCode : 1);
    }

    if (testEnv.resetTarget)
    {
        printTrace("Resetting target...");

        // Reset target.
        try
        {
            dsArray[core].target.reset();
        }
        catch (ex)
        {
            errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", could reset target!\nAborting!");
            quit(errCode != 0 ? errCode : 1);
        }
    }
    } for (var core = 0; core < autotestEnv.ccsCpu.length; core++) { //close and re-open for loop

    // Load and run each program provided.
    java.lang.System.out.println("autotestEnv.outFiles: " + autotestEnv.outFile);

        if (autotestEnv.outFile.length == 1) {
            outFile = autotestEnv.outFile[0];
        }
        else {
            outFile = autotestEnv.outFile[core];
        }
        printTrace("Loading " + outFile);

        // Load program and pass arguments to main (if applicable).
        try
        {
            if (testEnv.initBss)
            {
                dsArray[core].memory.setBssInitValue(testEnv.initBssValue);
            }

            if (testEnv.argvArgs.length < 2)
            {
                dsArray[core].memory.loadProgram(outFile);
            }
            else
            {
                dsArray[core].memory.loadProgram(outFile, testEnv.argvArgs);
            }
        }
        catch (ex)
        {
            errCode = getErrorCode(ex);
            printTrace("Error code #" + errCode + ", " + outFile + " load failed!\nAborting!");
            quit(errCode != 0 ? errCode : 1);
        }

        printTrace("Done");

        load(java.lang.System.getenv("LOADTI_PATH") + "/memXfer.js");

        // Load data from the host to target memory (if applicable).
        if ((testEnv.loadRaw.length > 0) || (testEnv.loadDat.length > 0))
        {
            printTrace("Loading data to target memory...");

            errCode = memLoad(dssScriptEnv, dsArray[core], testEnv.loadRaw, testEnv.loadDat);

            if (errCode != 0)
            {
                printTrace("Memory load failed with errCode: " + errCode);
            }
            else
            {
                printTrace("Done");
            }
        }

        if (!testEnv.onlyLoad)
        {

            // Set script timeout value for run API.
            dssScriptEnv.setScriptTimeout(testEnv.timeoutValue);

            if (testEnv.cioFile != null)
            {
                // Begin CIO logging.
                dsArray[core].beginCIOLogging(testEnv.cioFile);
            }
        }
     } //close of loop

            // Run to end of program (or timeout) and return total cycles unless asynch run.
            try
            {
                // Is the target already at the end of the program? If so, do not try to run again.
                // Note: we need to check the existance of the symbol first, since the evaluate function does not, and will return errors if the symbol does not exist, causing the script to exit
                // Note: This check is to fix the following use case: if the debugger is configured to Auto Run to a label after program load but that label is not hit then the loadti script may cause the program to enter an infinite loop.
                var abort = false;
                for (var core = 0; core < dsArray.length; core++) {
                if ( ( dsArray[core].symbol.exists("C$$EXIT") && dsArray[core].expression.evaluate( "PC == C$$EXIT" ) ) ||
                     ( dsArray[core].symbol.exists("C$$EXITE") && dsArray[core].expression.evaluate( "PC == C$$EXITE") ) ||
                     ( dsArray[core].symbol.exists("abort") && dsArray[core].expression.evaluate( "PC == abort") ) ){
                        abort = true;
                     }
                }
                if (abort)
                {
                    printTrace( "Target failed to run to desired user label after program load, and is at end of program.  Script execution aborted." );
                } else {
                    // continue with running the program
                    if (!testEnv.asyncRun)
                    {
                        printTrace("Interrupt to abort . . .");

                        if (!testEnv.noProfile)
                        {
                            //debugSession.clock.runBenchmark() is not supported on multicore tests
                            var cycles = 0; //var cycles = debugSession.clock.runBenchmark();
                        }
                        else
                        {
                            //debugSession.target.run();
                            //Enable asynchronous core run feature
                            if (!autotestEnv.asyncRunCores)
                            {
                                printTrace("Regular simultaneous run . . .");
                                debugServer.simultaneous.run();
                            }
                            else
                            {
                                for (var core = 0; core < dsArray.length - 1; core++) {
                                    printTrace("Iterated runAsynch . . .");
                                    dsArray[core].target.runAsynch();
                                }
                                dsArray[dsArray.length - 1].target.run()
                            }
                        }
                    }
                    else
                    {
                        //debugSession.target.runAsynch();
                        debugServer.simultaneous.runAsynch(dsArray);
                    }
                }
            }
            catch (ex)
            {
                if (1) {
                    errCode = getErrorCode(ex);
                    if (errCode == 1001)
                    {
                        printTrace(">> OVERALL TIMED OUT");
                        debugServer.simultaneous.halt(dsArray);
                    }
                    else
                    {
                        dssScriptEnv.traceWrite("Error code #" + errCode +
                                ", error encountered during program execution!\nAborting!");
                        quit(errCode != 0 ? errCode : 1);
                    }
                } else {
                    for (var core = 0; core < dsArray.length; core++) {
                        if (errCode == 1001)
                        {
                            printTrace(">> OVERALL TIMED OUT");
                            dsArray[core].target.halt();
                        }
                        else
                        {
                            dssScriptEnv.traceWrite("Error code #" + errCode +
                                    ", error encountered during program execution!\nAborting!");
                            quit(errCode != 0 ? errCode : 1);
                        }
                    }
                }
            }

            if (testEnv.cioFile != null && !testEnv.asyncRun)
            {
                // Stop CIO logging.
                for (var core = 0; core < dsArray.length; core++) {
                    dsArray[core].endCIOLogging();
                }
            }

            // Set script timeout value to default.
            dssScriptEnv.setScriptTimeout(defaultTimeout);

            if (!testEnv.asyncRun && !testEnv.noProfile)
            {
                // Print cycle counts unless script timout occurred on program execution.
                if (errCode != 1001)
                {
                    printTrace("NORMAL COMPLETION: " + cycles + " cycles");
                }
            }

        try {
                for (var core = 0; core < dsArray.length; core++) {
                    saveElfData(dsArray[core]);
                    printTrace("saving...");
                }
        }
        catch (ex) {
            printTrace("test_type not defined: defaulting to printf");
        }

        // Save data from target memory to a file on the host (if applicable).
        if ((testEnv.saveRaw.length > 0) || (testEnv.saveDat.length > 0))
        {
            // Only dump data if it is not a asynchronous run.
            if (!testEnv.asyncRun)
            {
                printTrace("Saving data to file...");
                for (var core = 0; core < dsArray.length; core++) {
                    errCode = memSave(dssScriptEnv, dsArray[core], testEnv.saveRaw, testEnv.saveDat);
                    if (errCode != 0)
                    {
                        printTrace("Memory save failed with errCode: " + errCode);
                        retVal = errCode;
                    }
                }
                printTrace("Done");
            }
            else
            {
                printTrace("Memory save options are not supported with an asynchronous run!");
            }
        }
    // End automation.
    quit(retVal);
}

/*
 *  ======== saveElfData.js =========
 *  This script can be run from the Scripting Console in CCS to generate
 *  a coredump file for use with the xdc.rov.coredump command line utility.
 *
 *  Example Usage:
 *  > loadJSFile C:\Program Files\Texas Instruments\xdctools_3_21_00_60\packages\xdc\rov\coredump\saveElfData.js
 *
 *  // TODO - Do the path spaces work out ok?
 *
 */
function saveElfData(debugSession)
{
/* Specify any additional reads. */
var additionalReads = [
    //{base: 0x1840000, len: 0x48},
    //{base: 0x1848000, len: 1024}
];

/* Get the currently loaded executable from the active debug session. */
var executable = debugSession.symbol.getSymbolFileName();

/* Display the executable as a sanity-check. */
print("\nSaving data sections for executable: ");
print(executable);

/* Create a new elf instance. */
var elf = new Packages.ti.targets.omf.elf.Elf32();

/* Parse the ELF file. */
print("\nParsing the ELF file...");
elf.parse(executable);

var index = 0;
var hdr;

/* Get a valid number for the data page. */
var dataPage = debugSession.memory.getPage(1);

print("Saving data sections....");

/* Create the .raw file right next to the executable. */
var rawPath = executable + ".raw";

/*
 * Create a RandomAccessFile for writing the coredump. This class is convenient
 * because it provides a method for writing Java Integers as four bytes.
 */
var outFile = new Packages.java.io.RandomAccessFile(rawPath, "rw");

/* Delete any existing contents. */
outFile.setLength(0);

/* For each section header... */
while ((hdr = elf.getSectionHeader(index++)) != null) {
    /*
     * Most of the data sections appear to be type '8'.
     * Skip sections that are length 0 or address 0.
     * TODO - How to include .const generically? .const is type '1', but so are
     * .text and many .debug_* sections...
     */
    if (((hdr.sh_type == 8) && (hdr.sh_addr != 0) && (hdr.sh_size != 0)) || (((hdr.name == ".const") || (hdr.name == ".rodata") || (hdr.name == ".data")) && (hdr.sh_size != 0)))
    {
        var baseAddr = hdr.sh_addr;

        /* Correct for sign extension. */
        if (baseAddr < 0) {
            baseAddr += Math.pow(2, 32);
        }

        var length = hdr.sh_size;

        /* Print out this section's name, address, and size. */
        print("  " + strPad(hdr.name, 12) + " addr: 0x" +
              Number(baseAddr).toString(16) + " size: " + length);

		// This work around skips big sections. If loggerbuf is in big memory section this may break.
		if(length > 0xc00000)
			continue;
        /* Save the data section to the dump file. */
        try {
            var data = debugSession.memory.readData(dataPage, baseAddr, 8, length);
        }
        catch (e) {
            print("Caught exception trying to read memory: " + e);
        }

        /* Validate the memory read. */
        if (data.length != length) {
            print("Error! Requested " + length + " bytes, received " +
                  data.length + " values.");
            break;
        }

        /*
         * Explicitly cast the base address to an integer (before passing
         * to 'writeInt'). The value may become negative if the MSB is set,
         * but the bits written to the file will be correct.
         */
        baseAddr = (new Packages.java.lang.Long(baseAddr)).intValue();

        /* Write the base address and length. */
        outFile.writeInt(baseAddr);
        outFile.writeInt(length);

        /* Write out all of the data. */
        for each (var val in data) {
            outFile.writeByte(Number(val));
        }
    }
}

/*
 * Handle any additional memory reads specified by the user in the
 * 'additionalReads' array.
 */
for each (var read in additionalReads) {

    /* Print out this section's name, address, and size. */
    print("  User spec.   addr: 0x" +
          Number(read.base).toString(16) + " size: " + read.len);

    /* Save the data section to the dump file. */
    try {
        var data = debugSession.memory.readData(dataPage, read.base, 8, read.len);
    }
    catch (e) {
        print("Caught exception trying to read memory: " + e);
    }

    /* Validate the memory read. */
    if (data.length != read.len) {
        print("Error! Requested " + read.len + " bytes, received " +
              data.length + " values.");
        break;
    }

    /*
     * Explicitly cast the base address to an integer (before passing
     * to 'writeInt').
     */
    read.base = (new Packages.java.lang.Long(read.base)).intValue();

    /* Write the base address and length. */
    outFile.writeInt(read.base);
    outFile.writeInt(read.len);

    /* Write out all of the data. */
    for each (var val in data) {
        outFile.writeByte(Number(val));
    }
}

/* Close the combined file. */
outFile.close();

print("\nData written to " + rawPath);

print("\nDone.");

/*
 *  ======== strPad ========
 *  Pads 'str' with 'pad' number of whitespace characters to the right.
 */
function strPad(str, pad)
{
    for (i = str.length(); i < pad; i++) {
        str += " ";
    }
    return(str);
}
}
