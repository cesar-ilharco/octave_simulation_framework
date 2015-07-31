%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function created_packets = CreatePackets (num_packets, packet_size_bytes, target_bitrate_kbps, last_id, last_send_time_ms)
	
  kPacketIntervalMs = 8*packet_size_bytes/target_bitrate_kbps;
  creation_times_ms = kPacketIntervalMs*(1:num_packets) + last_send_time_ms;
  packet_ids = (1:num_packets) + last_id;
  created_packets = [creation_times_ms; packet_ids; packet_size_bytes*ones(1,num_packets)];

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%