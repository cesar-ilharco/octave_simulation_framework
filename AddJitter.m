%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Equivalent to bwe_simulation_framework JitterFilter.
function jittered_packets = AddJitter (packets)
  
  kMaxJitterMs = 15;
  kSigmaMs = 5;

  num_packets = size(packets, 2);
  jittered_packets = packets;
  previous = 0;

  for i=1:num_packets
    jittered_packets(1,i) = packets(1,i) + min(abs(kSigmaMs*stdnormal_rnd(1)), kMaxJitterMs);
    jittered_packets(1,i) = max(previous, jittered_packets(1,i));
    previous = jittered_packets(1,i);
  endfor

endfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%