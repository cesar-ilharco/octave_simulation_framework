%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Equivalent to bwe_simulation_framework ChokeFilter.
function updated_packets = AddSendTime(packets, capacity_kbps)

  kBottleneckQueueSizeMs = 30;
  
  timestamps = packets(1,:);
  travel_time_ms = 8*packets(3,:) / capacity_kbps;
  num_packets = size(timestamps, 2);

  if (travel_time_ms(1) <= kBottleneckQueueSizeMs)
	  updated_packets(1,1) = timestamps(1) + travel_time_ms(1);
	  updated_packets(2,1) = packets(2,1);
  endif

  j = 2;
  for i = 2:num_packets
    new_timestamp = max(timestamps(i), updated_packets(1,j-1)) + travel_time_ms(i);
    if (new_timestamp - timestamps(i) <= kBottleneckQueueSizeMs)
    	updated_packets(1,j) = new_timestamp;
    	updated_packets(2,j) = packets(2,i);
    	j = j + 1;
    endif
  endfor
  
endfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%