function PlotNadaFilter (num_packets)
	
  % Use delay as a signal
  % 1) Subtract Baseline
  % 2) Apply Median filter
  % 3) Apply Exponential Smoothing Filter

  delays = Delays (num_packets);

  delay_signal = delays - Baseline(delays); 
  median_filtered = MedianFilter (delay_signal);
  exp_filtered = ExpSmoothingFilter(median_filtered);

  kThreshold = 6.5*ones(1,num_packets);
  decision =  (exp_filtered > kThreshold);

  plot(delay_signal,'r','LineWidth',1, 
       median_filtered, 'linestyle', ':','k', 'LineWidth', 4, 
       exp_filtered,'k', 'LineWidth',4,
       kThreshold, 'linestyle', '--', 'b', 'LineWidth',2,
       decision, 'b', 'LineWidth',3);

endfunction