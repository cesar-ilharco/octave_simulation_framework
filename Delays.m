function delays = Delays (num_packets)

    kCapacityKbps = 1000;
    kTargetBitrateKbps = 800;
    kPacketSizeBytes = 1200;
  
	creation_packets = CreationTimes (num_packets, kTargetBitrateKbps, kPacketSizeBytes);
	arrival_packets = ArrivalTimes (creation_packets, kCapacityKbps);
	delays = arrival_packets(1,:) - creation_packets(1,:);
	
endfunction