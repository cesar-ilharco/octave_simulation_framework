%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Equivalent to bwe_simulation_framework ChokeFilter.
function updated_packets = AddSendTime(packets, capacity_kbps, last_send_time_ms)

  kBottleneckQueueSizeMs = 30;
  
  timestamps = packets(1,:);
  travel_time_ms = 8*packets(3,:) / capacity_kbps;
  num_packets = size(timestamps, 2);
  updated_packets = [];

  j = 1;
  for i = 1:num_packets
    new_timestamp = max(timestamps(i), last_send_time_ms) + travel_time_ms(i);
    if (new_timestamp - timestamps(i) <= kBottleneckQueueSizeMs)
    	updated_packets(:,j) = packets(:,i);
      updated_packets(1,j) = new_timestamp;
      last_send_time_ms = updated_packets(1,j);
    	j = j + 1;
    endif
  endfor
  
endfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%