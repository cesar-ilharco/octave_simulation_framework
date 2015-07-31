%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function arrival_packets = ArrivalPackets (created_packets, capacity_kbps, last_arrived_ms)

  arrival_packets = AddPathDelay(created_packets);
  arrival_packets = AddSendTime(arrival_packets, capacity_kbps, last_arrived_ms);
  if (size(arrival_packets, 2) > 0)
     arrival_packets = AddJitter(arrival_packets, last_arrived_ms);
  endif
endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%