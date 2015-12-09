%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% packets(8) stores the timestamps. This function computes the time_weighted_average of a metric, 
% weighted by time.
function time_weighted_average = TimeWeightedtime_weighted_average (packets, metric_index)

  num_packets = size(packets, 2);
  time_weighted_average = 0;
  kTimeIndex = 8;

  for i=2:num_packets
  	delta_time_ms = packets(kTimeIndex,i)-packets(kTimeIndex,i-1);
    average = (packets(metric_index, i)+packets(metric_index, i-1))/2;
    time_weighted_average = time_weighted_average + delta_time_ms*average;
  endfor

  total_time_ms = packets(8, end);
  time_weighted_average = time_weighted_average/total_time_ms;

endfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%