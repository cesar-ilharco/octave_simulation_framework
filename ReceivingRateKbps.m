%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function receiving_rate = ReceivingRateKbps(packets)

  kTimeWindowMs = 200;
  
  newest_packet_ms = packets(1, end);
  time_limit = newest_packet_ms - kTimeWindowMs;

  total_received_bytes = 0;
  num_packets_received = 0;
  
  num_packets = size(packets, 2);
  for i=num_packets:-1:1
    oldest_packet_ms = packets(1, i);
    total_received_bytes = total_received_bytes + packets(3,i);
    num_packets_received = num_packets_received + 1;
    if (packets(1,i) < time_limit)
    	break;
    endif
  endfor
  if (num_packets_received == 0)
    receiving_rate = 0;
  elseif (num_packets_received == 1)
    receiving_rate = (8 * total_received_bytes) / kTimeWindowMs;
  else
    receiving_rate = (num_packets_received - 1)*(8 * total_received_bytes) / (num_packets_received*(newest_packet_ms-oldest_packet_ms));
  endif
endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%