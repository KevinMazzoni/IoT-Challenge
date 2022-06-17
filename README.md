# IoT-Challenge
Project done for IoT Class
This project consists of two sensors communicating each other. The first sensor starts immediately, it starts a timer which expires every one second. When it is fired, the sensor sends a REQ message to node 2, requires an ACK for that message and waits for a response. When it gets N responses (set to 6), it stops the timer and the communication is closed.
On the other hand, the second sensor waits 3 second and activates. When it receives one REQ message from the sensor 1, it responds with an ACK, then reads one value (we generate it randomly) and sends it back to sensor 1, asking for an ACK.
