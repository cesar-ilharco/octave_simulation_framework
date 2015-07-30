%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function creation_packets = CreationTimes (num_packets, target_bitrate_kbps, packet_size_bytes)
	
  kPacketIntervalMs = 8*packet_size_bytes/target_bitrate_kbps;
  creation_times = kPacketIntervalMs*(1:num_packets);
  packet_ids = (1:num_packets);
  creation_packets = [creation_times; packet_ids; packet_size_bytes*ones(1,num_packets)];

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%