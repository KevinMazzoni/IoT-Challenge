/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 sends requests to node 2 until it receives last_digit responses.
 *  Node 2 starts 3 seconds later than node 1, this is done in the TunSimulationScript.py file
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Kevin Mazzoni
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
    interface Receive;
    interface AMSend;
    interface SplitControl;
    
	//interface for timer
	interface Timer<TMilli> as MilliTimer;
	
    //other interfaces
    interface Packet;
    interface PacketAcknowledgements;
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t last_digit = 6;
  uint8_t counter = 0;
  uint8_t acks = 0;
  bool locked = FALSE;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	 my_msg_t* rcm = (my_msg_t*) call Packet.getPayload(&packet, sizeof(my_msg_t));
	 
	 if(rcm == NULL || locked){return;}
	 
	 rcm -> msg_type = REQ;
	 rcm -> msg_counter = counter;
	 rcm -> msg_value = 0;
	 
	 if(call PacketAcknowledgements.requestAck(&packet) != SUCCESS){return;}
	 
	 if (call AMSend.send(MOTE2, &packet, sizeof(my_msg_t)) == SUCCESS) {
		dbg("radio_send", "Sending packet of type REQ from Mote 1 to Mote 2");	
		locked = TRUE;
		dbg_clear("radio_send", " at time %s \n", sim_time_string());
		
	  }

 }        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raises the event read done.
  	 */
  	 
	 call Read.read();
	 
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    
    if (err == SUCCESS) {
      	dbg("radio","Radio on on node %d!\n", TOS_NODE_ID);
      	
      	if(TOS_NODE_ID == 1){						//Mote #1 - it sends requests periodically every 1 minute, we've to start a timer
			call MilliTimer.startPeriodic(1000);
		}

    }
    
  }
  
  event void SplitControl.stopDone(error_t err){
	dbg("boot", "Radio stopped!\n");
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 */
	 counter ++;
	 dbg("timer", "Mote %hu, Timer fired, counter is %hu.\n", TOS_NODE_ID, counter);
	 
	 if(locked){return;}
	 
	 sendReq();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer according to your id. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if (&packet == buf) {
      locked = FALSE;
      dbg("radio_send", "Packet sent...");
      dbg_clear("radio_send", " at time %s \n", sim_time_string());
      
      if(call PacketAcknowledgements.wasAcked(&packet) && TOS_NODE_ID == 1){
      	acks ++;
		dbg("ACK", "Packet sent from Mote 1 acknowledged by Mote 2, acks received at Mote 1: %hu\n", acks);	
	  	if(acks == last_digit){
	  		dbg("timer","LAST ACK RECEIVED, TIMER STOPPED AT TIME: %s\n", sim_time_string());
	  		call MilliTimer.stop();
	  	}
	  }
	  else if(call PacketAcknowledgements.wasAcked(&packet) && TOS_NODE_ID == 2){
	  	dbg("ACK", "Packet sent from mote 2 acknowledged by mote 1\n");
	  	
	  	if(acks == last_digit){				//The program for Mote 2 is done, stop the split control.
	  		call SplitControl.stop();
	  	}	
	  }
	  else{
		dbgerror("ACK", "Packet sent from mote %hu not acknowledged by mote %hu\n", ((TOS_NODE_ID == 1) ? 1 : 2), ((TOS_NODE_ID == 1) ? 2 : 1));
		sendReq();
	  }
			
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	 if(len != sizeof(my_msg_t)){
	 	return buf;
	 }
	 
	 else{
	 	my_msg_t* rcm = (my_msg_t*) payload;
	 	
	 	dbg("radio_rec", "Received packet at time %s at mote %hu\n", sim_time_string(), TOS_NODE_ID);
		dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ));
		 
		dbg_clear("radio_pack","\t\t Payload \n" );
		dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", rcm -> msg_type);
		dbg_clear("radio_pack", "\t\t msg_counter: %hhu \n", rcm -> msg_counter);
		dbg_clear("radio_pack", "\t\t msg_value: %hhu \n", rcm -> msg_value);
		
		counter = (rcm -> msg_counter);
		 
		if(rcm -> msg_type == REQ){			//This means Mote #2 receives a request from Mote #1
			sendResp();			
		}
		/*
		else{								//This means Mote #1 receives a RESPONSE from Mote #2	

			if(acks == last_digit){
		 		//We have only to send the last ACK and the program is done
		 		call SplitControl.stop();
		 	}
		}
		*/
		 
		return buf;
	 
	 }

  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finishes to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */

	 
	 my_msg_t* rcm = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	 
	 double value = ((double)data/65535)*100;
	 dbg("value","value read done %f\n",value);
	 
	 if(rcm == NULL || locked){
	 	return;
	 }
	 else{
		 rcm -> msg_type = RESP;
		 rcm -> msg_counter = counter;
		 rcm -> msg_value = value;
		 
		 if(call PacketAcknowledgements.requestAck(&packet) != SUCCESS){return;}
		 
		 if (call AMSend.send(MOTE1, &packet, sizeof(my_msg_t)) == SUCCESS) {
			dbg("radio_send", "Sending packet RESP from mote 2 to mote 1");	
			locked = TRUE;
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
		
		  }
	 
	 }
	
  }
	
}

