function creation_times = CreationTimes (num_packets)
	
  kPacketIntervalMs = 15;
  creation_times = kPacketIntervalMs*(1:num_packets);

endfunction