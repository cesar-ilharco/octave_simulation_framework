%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function receiving_rate = ReceivingRateKbps(packets)

  kTimeWindowMs = 500;
  
  num_packets = size(packets, 2);
  time_limit = packets(1, num_packets) - kTimeWindowMs;
  total_received_bytes = 0;

  for i=num_packets:-1:1
    if (packets(1,i) < time_limit)
    	break;
    endif
    total_received_bytes = total_received_bytes + packets(3,i);
  endfor

  receiving_rate = (8 * total_received_bytes) / kTimeWindowMs;
endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%