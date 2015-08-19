# octave_simulation_framework

OBJECTIVES:
The repository aims to provide a simulation framework that is easy to read, run and modify. Results visualization helps to get a better understanding on how congestion control algorithms GCC and NADA work. Furthermore, new filters and other algorithm modifications can be tested.

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
Calling RunNadaFilter() will simulate the evaluation test case 5.1, available on:
https://tools.ietf.org/html/draft-ietf-rmcat-eval-test-01#section-5.1

Adjust/tune parameters according to your needs.

TODO:
Implement GCC congestion control algorithm on this framework.
Test other filters/classifiers as alternatives to Kalman filter.
