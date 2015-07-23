function inter_group_delay_variation = InterGroupDelayVariation (num_packets)

	delays = Delays(num_packets);
	inter_group_delay_variation = delays(2:num_packets) - delays(1:num_packets-1);
	
endfunction