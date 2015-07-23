function delays = Delays (num_packets)

	creation_times = CreationTimes (num_packets);
	arrival_times = ArrivalTimes (creation_times);
	delays = arrival_times - creation_times;
	
endfunction