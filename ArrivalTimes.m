function arrival_times = ArrivalTimes (creation_times)
	
  kOneWayPathDelayMs = 50;
  kPacketSizeBytes = 1200;
  kBottleneckQueueSizeMs = 15;

  num_packets = size(creation_times, 2);

  arrival_times = kOneWayPathDelayMs + creation_times;

  % Lower capacity, congestion in the middle third of the packets.
  
  capacity_kbps = 1000 - 370*(1:num_packets>num_packets/3).*(1:num_packets<=2*num_packets/3);
  travel_times_ms = 8*kPacketSizeBytes ./ capacity_kbps;

  arrival_times(1,1) = arrival_times(1,1) + travel_times_ms(1,1);
  for i=2:num_packets
  	arrival_times(1,i) = min(arrival_times(1,i) + kBottleneckQueueSizeMs, max(arrival_times(1,i), arrival_times(1,i-1)) + travel_times_ms(1,i));
  endfor

  arrival_times = AddJitter(arrival_times);

endfunction