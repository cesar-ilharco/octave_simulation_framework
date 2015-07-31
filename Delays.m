function delays = Delays (num_packets, payload_bytes, target_kbps, capacity_kbps)

	created_packets = CreatePackets (num_packets, payload_bytes, target_kbps, 0, 0);
	arrival_packets = ArrivalPackets (created_packets, capacity_kbps);
	delays = arrival_packets(1,:) - created_packets(1,:);
	
endfunction