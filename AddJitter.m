function jittered_timestamps = AddJitter (timestamps)
	
  kMaxJitterMs = 15;
  kSigmaMs = 5;

  num_packets = size(timestamps, 2);
  jittered_timestamps = timestamps;
  previous = 0;

  for i=1:num_packets
    jittered_timestamps(1,i) = jittered_timestamps(1,i) + min(abs(kSigmaMs*stdnormal_rnd(1)), kMaxJitterMs);
    jittered_timestamps(1,i) = max(previous, jittered_timestamps(1,i));
    previous = jittered_timestamps(1,i);
  endfor

endfunction