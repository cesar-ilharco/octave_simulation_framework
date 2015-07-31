%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function arrival_packets = ArrivalPackets (created_packets, capacity_kbps)

  arrival_packets = AddPathDelay(created_packets);
  arrival_packets = AddSendTime(arrival_packets, capacity_kbps);
  arrival_packets = AddJitter(arrival_packets);

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%