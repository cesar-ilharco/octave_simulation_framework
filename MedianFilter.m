%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function median_filtered = MedianFilter (array)
	
  kMedian = 5;
  num_packets = size(array, 2);

  median_filtered = array;

  for i=2:num_packets
    left = max(1, i-kMedian+1);
    median_filtered(1,i) = median(array(left:i));
  endfor

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%