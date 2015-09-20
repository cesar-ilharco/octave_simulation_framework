%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Equivalent to bwe_simulation_framework JitterFilter.
function jittered_packets = AddJitter (packets, last_send_time_ms)
  
  % High jitter.
  kMaxJitterMs = 60;
  kSigmaMs = 20;
  kDefaultValues = false;

  if (kDefaultValues)
	  kMaxJitterMs = 30;
	  kSigmaMs = 15;
  endif

  num_packets = size(packets, 2);
  jittered_packets = packets;

  for i=1:num_packets
  	jitter = kSigmaMs*stdnormal_rnd(1);
    if (kDefaultValues)
    	jitter = sign(jitter)*min(abs(jitter), kMaxJitterMs);
    else
		  jitter = min(abs(jitter), kMaxJitterMs);
	   endif
    jittered_packets(1,i) = packets(1,i) + jitter;
    jittered_packets(1,i) = max(last_send_time_ms, jittered_packets(1,i));
    last_send_time_ms = jittered_packets(1,i);
  endfor

endfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%