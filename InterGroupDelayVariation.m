%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function inter_group_delay_variation = InterGroupDelayVariation (num_packets, payload_bytes, target_kbps, capacity_kbps)

	delays = Delays(num_packets, payload_bytes, target_kbps, capacity_kbps);
	inter_group_delay_variation = delays(2:num_packets) - delays(1:num_packets-1);

	plot(delays,'r','LineWidth',2,
	     inter_group_delay_variation, 'b', 'LineWidth',2);
	
endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%