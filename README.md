# octave_simulation_framework  
Using GNU Octave, version 3.6.1  

------------------------------------------------------------------------------------------------------
The currently supported version of this framework was written in Python:  
https://github.com/c-ilharco-magalhaes/rmcat_evaluation  

------------------------------------------------------------------------------------------------------
OBJECTIVES:  
The repository aims to provide an octave simulation framework that is easy to read, run and modify. Results visualization helps to get a better understanding on how congestion control algorithms GCC and NADA work. Furthermore, new filters and other algorithm modifications can be tested.

------------------------------------------------------------------------------------------------------
ABOUT:  
This framework simulates:  
A sender that creates packets, with a pace determined by the sending bitrate and the packet size.  
Packets are submitted to:  
   Delay filter: adds latency - minimum one way path delay.  
   Choke filter: adds travel time. Packet can be lost if delay > bottleneck queuing size.  
   Jitter filter: adds noise to the arrival time.  
   (Those filters simulate effect of the packet traveling through the channel link).  
A receiver then gets the packets with updated timestamps.  

------------------------------------------------------------------------------------------------------
NADA congestion control algorithm is implemented, according to the internet draft (work in progress):  
https://tools.ietf.org/html/draft-ietf-rmcat-nada-00  

------------------------------------------------------------------------------------------------------
HOW TO USE:  
Calling RunNada(EvaluationTest1()) from Octave will simulate the evaluation test case 5.1, available on:  
https://tools.ietf.org/html/draft-ietf-rmcat-eval-test-01#section-5.1  

Adjust/tune parameters according to your needs.  

------------------------------------------------------------------------------------------------------
Since jitter is always positive, using a min filter instead of a median filter can be a good alternative to measure how much of the delay isn't due to jitter. Travel time depends on the link capacity. A 1200 bytes packet will naturally have a 15ms higher delay over a 500kbps than over a 2500kbps network. This can affect NADA's performance if the capacity drops: the baseline_delay won't be updated. One solution can be update it over a previous time window. Another one can be estimate the current send time.

------------------------------------------------------------------------------------------------------
RESULTS: In a constant 1500 kbps link capacity high jitter scenario, the modified ADA version achieves a significantly higher throughput compared with the original one. The min filter seems to be a good option to reduce jitter sensitiveness.  

------------------------------------------------------------------------------------------------------
The modifications to NADA algorithm that were implemented on:  
https://chromium.googlesource.com/external/webrtc/+/master/webrtc/modules/remote_bitrate_estimator/test/estimators/nada.cc  
were also implemented in this branch.

------------------------------------------------------------------------------------------------------
TODO:  
Implement GCC congestion control algorithm on this framework.  
Test other filters/classifiers as alternatives to Kalman filter.  
