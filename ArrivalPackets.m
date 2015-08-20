%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [arrival_packets new_send_time_ms] = ArrivalPackets (created_packets, capacity_kbps, last_send_time_ms, last_arrived_ms)
  
  arrival_packets = AddPathDelay(created_packets);
  % On the chrome repository C++ simulation framework
  % https://chromium.googlesource.com/external/webrtc/+/master/webrtc/modules/remote_bitrate_estimator/test/bwe_test_framework.cc
  % last_send_times are independent for jitter and choke filter.
  new_send_time_ms = last_send_time_ms;
  arrival_packets = AddSendTime(arrival_packets, capacity_kbps, last_send_time_ms);
  % Add jitter if at least one packet was not lost.
  if (size(arrival_packets, 2) > 0)
  	 new_send_time_ms = arrival_packets(1, end);
     arrival_packets = AddJitter(arrival_packets, last_arrived_ms);
  endif

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%