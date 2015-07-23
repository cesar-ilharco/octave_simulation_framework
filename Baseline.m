function baseline = Baseline (array)

  num_packets = size(array, 2);
  baseline = array;

  for i=2:num_packets
    baseline(1,i) = min(baseline(1,i-1), baseline(1,i));
  endfor

endfunction