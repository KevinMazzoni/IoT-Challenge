/**
 *  @author Kevin Mazzoni
 */

#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
	nx_uint8_t msg_type;
  	nx_uint16_t msg_counter;
	nx_uint16_t msg_value;
} my_msg_t;

#define REQ 1
#define RESP 2
#define MOTE1 1
#define MOTE2 2

enum{
AM_MY_MSG = 6,
};

#endif
