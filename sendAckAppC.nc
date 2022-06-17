/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Kevin Mazzoni
 */

#include "sendAck.h"

configuration sendAckAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, sendAckC as App;
  
  //other components
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC();
  components new FakeSensorC();
  components ActiveMessageC;

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot; 
  

  /****** Wiring the other interfaces down here *****/
  //Send and Receive interfaces
  //Radio Control
  //Interfaces to access package fields
  //Timer interface
  //Fake Sensor read
  App.Read -> FakeSensorC;
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.SplitControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements -> ActiveMessageC;

}

