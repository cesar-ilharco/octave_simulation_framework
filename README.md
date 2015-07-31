# octave_simulation_framework

ABOUT:
This framework simulates:
A sender that creates packets, with a pace determined by the sending bitrate and the packet size.
Packets are submitted to:
   Delay filter: adds latency - minimum one way path delay.
   Choke filter: adds travel time. Packet can be lost if delay > bottleneck queuing size.
   Jitter filter: adds noise to the arrival time.
   (Those filters simulate effect of the packet traveling through the channel link).
A receiver then gets the packets with updated timestamps.

NADA congestion control algorithm is implemented, according to:
https://tools.ietf.org/html/draft-ietf-rmcat-nada-00
(Work in progress)

HOW TO USE:
Call RunNadaFilter(num_packets) with the chosen number of packet.
Adjust/tune parameters according to your needs.

TODO:
Implement GCC congestion control algorithm on this framework.
Test other filters/classifiers as alternatives to Kalman filter.
