%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sequence numbers are sequential.
function loss_ratio = LossRatio(packets)
  kTimeWindowMs = 500;
  num_packets = size(packets, 2);
  time_limit = packets(1, num_packets) - kTimeWindowMs;
  packets_received = 0;
  for i=num_packets:-1:1
    if (packets(1,i) < time_limit)
    	break;
    endif
    packets_received = packets_received + 1;
  	oldest_seq_number = packets(2,i);
  endfor

  newest_seq_number = packets(2,num_packets);

  loss_ratio = 1.0 - packets_received/(newest_seq_number - oldest_seq_number + 1);
  
endfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%