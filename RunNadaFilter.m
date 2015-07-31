%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RunNadaFilter (num_packets)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Constants.
  kCapacityKbps = 500;
  kPacketLossPenaltyMs = 1000;
  kPayloadSizeBytes = 1200;
  kMinBitrateKbps = 150;
  kMaxBitrateKbps = 1500;
  kFeedbackIntervalMs = 100;
  kQueuingDelayUpperBoundMs = 10;
  kDerivativeUpperBound = 10 / kFeedbackIntervalMs;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Members, initial value.
  bitrate_kbps_ = 1000;
  now_sender_ms_ = 0;
  now_receiver_ms_ = 0;
  arrival_packets_ = [];
  % now, congestion_signal.
  feedbacks_ = [0; 0];   
  baseline_delay_ms_ = 10000;  % Upper bound.
  % bitrate, delay_signal, median_filtered, exp_smoothed, est_queuing_delay, loss_ratio, congestion_signal.
  plot_values = [0; 0; 0; 0; 0; 0; 0];
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  for packet_id=1:num_packets
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SENDER SIDE: Generate packets one by one.

    new_packet = CreatePackets (1, kPayloadSizeBytes, bitrate_kbps_, packet_id-1, now_sender_ms_);
    now_sender_ms_ = new_packet(1,1);

    arrival_packet = ArrivalPackets (new_packet, kCapacityKbps, now_receiver_ms_);

    % Packets can be lost.
    if (size(arrival_packet, 2) > 0)
      % Use delay as a signal.
      % 1) Subtract Baseline. 
      % 2) Apply Median filter.
      % 3) Apply Exponential Smoothing Filter.
      % 4) Non-linear Estimate queuing delay warping.
      delay = arrival_packet(1,1) - new_packet(1,1);
      baseline_delay_ms_ = min (baseline_delay_ms_, delay);
      delay_signal = delay - baseline_delay_ms_;
      median_filtered = MedianFilter ([plot_values(2,max(1,end-4):end) delay_signal])(end);
      exp_smoothed = ExpSmoothingFilter([plot_values(4,end) median_filtered])(2);
      est_queuing_delay_ms = NonLinearWarping(exp_smoothed);

      % Use loss as a signal.
      arrival_packets_ = [arrival_packets_ arrival_packet];
      loss_ratio = LossRatio(arrival_packets_);
      % Truncate stored packets to prevent it to be too large.
      if (size(arrival_packets_, 2) > 1000)
         arrival_packets_ = arrival_packets_(:,500:end);
      endif

      congestion_signal_ms = est_queuing_delay_ms + loss_ratio*kPacketLossPenaltyMs;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % RECEIVER SIDE: 
      now_receiver_ms_ = arrival_packet(1,1);
      % Generate and process feedback --- Update bitrate_kbps_.
      if (now_receiver_ms_ - feedbacks_(1,end) >= kFeedbackIntervalMs)
        delta_ms = now_receiver_ms_ - feedbacks_(1,end);
        derivative = (congestion_signal_ms - feedbacks_(2,end)) / delta_ms;
        % AcceleratedRampUp
        if (loss_ratio == 0 && est_queuing_delay_ms < kQueuingDelayUpperBoundMs && derivative < kDerivativeUpperBound)
          kMaxRampUpQueuingDelayMs = 50;  % Referred as T_th.
          kGamma0 = 0.5;                  % Referred as gamma_0.
          kGamma = min(kGamma0, kMaxRampUpQueuingDelayMs/(baseline_delay_ms_ + kFeedbackIntervalMs));
          bitrate_kbps_ = (1.0 + kGamma) * ReceivingRateKbps(arrival_packets_);
        else   % GradualRateUpdate
          kTauOMs = 500.0;           % Referred as tau_o.
          kEta = 2.0;                % Referred as eta.
          kKappa = 1.0;              % Referred as kappa.
          kReferenceDelayMs = 10.0;  % Referred as x_ref.
          kPriorityWeight = 1.0;     % Referred as w.
          x_hat = congestion_signal_ms + kEta*kTauOMs*derivative;
          kTheta = kPriorityWeight * (kMaxBitrateKbps - kMinBitrateKbps) * kReferenceDelayMs;
          increase_kbps = kKappa*delta_ms*(kTheta - x_hat*(bitrate_kbps_ - kMinBitrateKbps)) / (kTauOMs^2);
          bitrate_kbps_ = bitrate_kbps_ + increase_kbps;
        endif
        % Bitrate should be kept between [kMin, kMax].
        bitrate_kbps_ = max(kMinBitrateKbps, min(kMaxBitrateKbps, bitrate_kbps_));
        feedback = [now_receiver_ms_; congestion_signal_ms];
        feedbacks_ = [feedbacks_ feedback];
      endif

      plot_value = [bitrate_kbps_; delay_signal; median_filtered; exp_smoothed; est_queuing_delay_ms; loss_ratio; congestion_signal_ms];
      plot_values = [plot_values plot_value];
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    endif

  endfor

  %%%%%%%% PLOT BITRATE %%%%%%%%
  figure(1);
  plot (plot_values(1,:), 'b', 'LineWidth',4,
        kCapacityKbps*ones(1,num_packets), 'linestyle', '--', 'k', 'LineWidth',2);

  %%%%%%%% PLOT delay_signal, median_filtered, exp_smoothed. %%%%%%%%
  figure(2);
  plot(plot_values(2,:),'r','LineWidth',1, 
       plot_values(3,:), 'linestyle', ':','k', 'LineWidth', 4, 
       plot_values(4,:),'k', 'LineWidth', 4);

  %%%%%%%% PLOT est_queuing_delay, loss_signal and congestion_signal. %%%%%%%%
  figure(3);
  plot(plot_values(5,:),'b','LineWidth',2, 
       kPacketLossPenaltyMs * plot_values(6,:),'r', 'LineWidth',2,
       plot_values(7,:),'k', 'LineWidth',4);

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%