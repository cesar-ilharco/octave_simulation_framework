function exp_filtered = ExpSmoothingFilter (array)
	
  kAlpha = 0.9;
  num_packets = size(array, 2);

  exp_filtered = array;

  for i=2:num_packets
    exp_filtered(1,i) = kAlpha*exp_filtered(1,i-1) + (1.0-kAlpha)*exp_filtered(1,i);
  endfor

endfunction