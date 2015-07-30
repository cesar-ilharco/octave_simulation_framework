%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function arrival_packets = ArrivalTimes (creation_packets, capacity_kbps)

  arrival_packets = AddPathDelay(creation_packets);
  arrival_packets = AddSendTime(creation_packets, capacity_kbps);
  arrival_packets = AddJitter(creation_packets);

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%