Target Server Flow:
nwsetup.c:    	This is the file that contains main() entry point. It initializes TCP/IP Stack and creates a Task to run DVTB. 
				This task calls dvtb_sock_listener() in dvtbHostIf.c
dvtbHostIf.c: 	Creates TCP IP Socket, binds it and start listening on it.
				Once a client connects to it, it accepts the connection and then calls dvtb_main() in dvtbMain.c
dvtbMain.c:		It calls dvtb_ceRuntimeInit, dvtb_initParams, dvtb_initThr and then
				do 
					Calls dvtb_raw_recv in dvtbHostIf.c, which calls the Socket's recv function with the wait flag set, in other words is a blocking function.
						recv(hostIf, ptr, size, MSG_WAITALL), on this call the pointer passed is the headerId and the size is #define PACKET_HDR      (1)
					then calls dvtb_recv in dvtbHostIf.c, which calls
					    DVTB_RECV(&len, PACKET_SIZE)
							recv(hostIf, ptr, size, MSG_WAITALL), on this call the pointer passed is "len" and the size is #define PACKET_SIZE     (4)
						DVTB_RECV((char *)ptr, len);
							recv(hostIf, ptr, size, MSG_WAITALL), on this call the pointer passed is "buff" the message buffer and the size is "len" read above
					dvtb_recv returns the number of chars in "buff"
					Calls dvtb_tokenize and passed "buff" and an array of string pointers ByRef
						dvtb_tokenize parsed "buff" and returns all tokens until char '\0' is found
					Then dvtb_execute(numTokens, parsedTokens) in dvtbDispatcher.c is called
						If the command to execute is not supported then dvtb_execute returns with value DVTB_NOTSUPPORTED 
						If the command to execute is "func" then an extra step is executed, which is
							dvtb_reportStatus in dvtbMain.c is called to send a response back to the client. 
							The response is send in three packets: DVTB_ASYNC_RESPONSE + Command + "PNDG"
						Finally the appropriate dvtbDispatcher function: dvtb_funcExecute |  dvtb_setpExecute | dvtb_getpExecute | dvtb_quit is called
						and if their return value is higher than zero then DVTB_SUCCESS is returned by dvtb_execute. One can see below mapping between
						commands names and function calls
						{"func", dvtb_funcExecute},		dvtb_funcExecute is implemented in dvtbFuncDispatcher.c
					    {"perf", NULL},
					    {"strs", NULL},
					    {"stbl", NULL},
					    {"apis", NULL},
					    {"setp", dvtb_setpExecute},		dvtb_setpExecute is implemented in dvtbSetParam.c
					    {"getp", dvtb_getpExecute},		dvtb_getpExecute is implemented in dvtbGetParam.c
					    {"ctrl", NULL},
					    {"quit", dvtb_quit}				dvtb_quit is implemented in dvtbDispatcher.c
					Finally dvtb_reportStatus is called again to send a response back to the client. 
					The response send back to the client depends on the return value of the function executed above and could be
						DVTB_RESPONSE + command +  "PASS", or
						DVTB_ERROR + command + "FAIL"
				while len > 0
				Once dvtb_main returns, dvtb_sock_listener() in dvtbHostIf.c close the socket and keep listening for another connection
				
				
					
					
					
				
				