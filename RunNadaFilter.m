%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RunNadaFilter (num_packets)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Constants.
  kPacketLossPenaltyMs = 1000;
  kPayloadSizeBytes = 1200;
  kMinBitrateKbps = 50;
  kMaxBitrateKbps = 2500;
  kFeedbackIntervalMs = 100;
  kQueuingDelayUpperBoundMs = 10;
  kDerivativeUpperBound = 10 / kFeedbackIntervalMs;
  kOriginalMode = false;
  kQueuingDelayUpperBoundMs = 10;
  kProportionalityDelayBits = 20;
  kMaxCongestionSignalMs = 50;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Testbed parameters: evaluation test 5.1 available on:
  % https://tools.ietf.org/html/draft-ietf-rmcat-eval-test-01#section-5.1
  % Maps [ending_time(s) capacity(kbps)]
  kCapacitiesKbps = [25 4000; 50 2000; 75 3500; 100 1000; 125 2000];
  % Simulation can be shorten in order to obtain results more quickly.
  % Convergence should take place before link capacity changes.
  time_compression = 1;  % Optional.
  kCapacitiesKbps (:,1) = kCapacitiesKbps (:,1)./time_compression;
  % Link capacity can be reduced to test a stressed scenario.
  reducing_factor = 5;  % Optional.
  kCapacitiesKbps (:,2) = kCapacitiesKbps (:,2)./reducing_factor;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Members, initial value.
  bitrate_kbps_ = 300;
  now_sender_ms_ = 0;
  now_receiver_ms_ = 0;
  last_send_time_ms_ = 0;
  arrival_packets_ = [];
  % now, congestion_signal.
  feedbacks_ = [0; 0];   
  baseline_delay_ms_ = 10000;  % Upper bound.
  % bitrate, delay_signal, median_filtered, exp_smoothed,
  % est_queuing_delay, loss_ratio, congestion_signal, time_ms, extra_delay.
  plot_values_ = zeros(9, 1);
  packet_id_ = 1;
  capacity_piece_ = 1;  % Link capacity changes and has several constant pieces.
  min_est_travel_time_ms_ = 10000; % Upper bound.
  extra_delay_ms_ = 0;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  while now_sender_ms_ < 1000 * kCapacitiesKbps(end,1);
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SENDER SIDE: Generate packets one by one.

    % Update capacity if necessary
    while now_sender_ms_ > 1000 * kCapacitiesKbps(capacity_piece_, 1)
      capacity_piece_ = capacity_piece_ + 1;
    endwhile

    current_capacity_kbps = kCapacitiesKbps(capacity_piece_, 2);

    new_packet = CreatePackets (
                 1, kPayloadSizeBytes, bitrate_kbps_, packet_id_-1, now_sender_ms_);
    now_sender_ms_ = new_packet(1,1);

    [arrival_packet last_send_time_ms_] = ArrivalPackets (
      new_packet, current_capacity_kbps, last_send_time_ms_, now_receiver_ms_);

    % Packets can be lost.
    if (size(arrival_packet, 2) > 0)
      % Use delay as a signal.
      % 1) Subtract Baseline. 
      % 2) Apply Median or Min filter.
      % 3) Apply Exponential Smoothing Filter.
      % 4) Non-linear Estimate queuing delay warping.
      delay = arrival_packet(1,1) - new_packet(1,1);
      baseline_delay_ms_ = min (baseline_delay_ms_, delay);
      delay_signal = delay - baseline_delay_ms_;
      if (kOriginalMode)
        median_filtered = MedianFilter ([plot_values_(2,max(1,end-3):end) delay_signal])(end);
      else 
        median_filtered = min ([plot_values_(2,max(1,end-8):end) delay_signal]);
      endif
      exp_smoothed = ExpSmoothingFilter([plot_values_(4,end) median_filtered])(2);
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
        if (kOriginalMode)
          % AcceleratedRampUp
          if (loss_ratio == 0 && est_queuing_delay_ms < kQueuingDelayUpperBoundMs 
                              && derivative < kDerivativeUpperBound)
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

        else  % Modified NADA.
          % Modified algorithm takes into account possible extra travel time for a packet.
          % If the capacity decreases, travel time will naturally increase.
          % An alternative to handle this case is to update the baseline_delay_ms only
          % during a latest time window. 
          receiving_rate = ReceivingRateKbps(arrival_packets_);
          est_travel_time_ms = 8*kPayloadSizeBytes/bitrate_kbps_;
          min_est_travel_time_ms_ = min(min_est_travel_time_ms_, est_travel_time_ms);
          extra_delay_ms_ = est_travel_time_ms - min_est_travel_time_ms_;
          % Stricter AcceleratedRampUp.
          if (loss_ratio == 0 && (exp_smoothed < extra_delay_ms_ - kQueuingDelayUpperBoundMs || exp_smoothed < kQueuingDelayUpperBoundMs/5) && 
              derivative < kDerivativeUpperBound && receiving_rate > kMinBitrateKbps)
            kMaxRampUpQueuingDelayMs = 50;  % Referred as T_th.
            kGamma0 = 0.5;                  % Referred as gamma_0.
            kGamma = min(kGamma0, kMaxRampUpQueuingDelayMs/(baseline_delay_ms_ + kFeedbackIntervalMs));
            bitrate_kbps_ = (1.0 + kGamma) * receiving_rate;
          % New AcceleratedRampDown mode.
          elseif (congestion_signal_ms > kMaxCongestionSignalMs 
                  || exp_smoothed > kMaxCongestionSignalMs)
            kGamma0 = 0.9;
            my_gamma = 5.0 * kMaxCongestionSignalMs / (congestion_signal_ms + exp_smoothed);
            my_gamma = min(my_gamma, kGamma0);
            bitrate_kbps_ = my_gamma * receiving_rate;
          % Smoothed GradualRateUpdate.
          else   
            bitrate_reference = 2.0*bitrate_kbps_/(kMaxBitrateKbps+kMinBitrateKbps);
            smoothing_factor = bitrate_reference ^ 0.75;
            kTauOMs = 500.0;           % Referred as tau_o.
            kEta = 2.0;                % Referred as eta.
            kKappa = 1.0;              % Referred as kappa.
            kReferenceDelayMs = 10.0;  % Referred as x_ref.
            kPriorityWeight = 1.0;     % Referred as w.
            x_hat = congestion_signal_ms + kEta*kTauOMs*derivative;
            kTheta = kPriorityWeight * (kMaxBitrateKbps - kMinBitrateKbps) * kReferenceDelayMs;
            increase_kbps = kKappa*delta_ms*(kTheta - x_hat*(bitrate_kbps_ - kMinBitrateKbps)) / (kTauOMs^2);
            bitrate_kbps_ = bitrate_kbps_ + increase_kbps * smoothing_factor;
          endif
          % Bitrate should be kept between [kMin, kMax].
          bitrate_kbps_ = max(kMinBitrateKbps, min(kMaxBitrateKbps, bitrate_kbps_));
          feedback = [now_receiver_ms_; congestion_signal_ms];
          feedbacks_ = [feedbacks_ feedback];
        endif
      endif

      plot_value = [bitrate_kbps_; delay_signal; median_filtered; exp_smoothed; 
                    est_queuing_delay_ms; loss_ratio; congestion_signal_ms; 
                    now_receiver_ms_; extra_delay_ms_];
      plot_values_ = [plot_values_ plot_value];
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    endif

    packet_id_ = packet_id_ + 1;

  endwhile

  %%%%%%%% PLOT BITRATE %%%%%%%%
  figure(1);

  plot_capacity_kbps = [0 kCapacitiesKbps(1, 2) ; kCapacitiesKbps(1,:)];
  for i=2:size(kCapacitiesKbps , 1)
      plot_capacity_kbps = [plot_capacity_kbps ; 
                            kCapacitiesKbps(i-1, 1) kCapacitiesKbps(i, 2); 
                            kCapacitiesKbps(i,:)];
  endfor

  plot (plot_values_(8,2:end)./1000, plot_values_(1,2:end), 'b', 'LineWidth', 4,
        plot_capacity_kbps(:,1), plot_capacity_kbps(:,2), 'linestyle', '--', 'k', 'LineWidth', 2);

  title('Sending estimate', 'fontsize', 16);
  xlabel('Time (s)', 'fontsize', 14);
  ylabel('Bitrate(kbps)', 'fontsize', 14);
  legend1 = legend ('Sending estimate', 'Link capacity');
  set (legend1, 'fontsize', 14);

  %%%%%%%% PLOT signals on the same window %%%%%%%%
  %%%%%%%% PLOT delay_signal, median_filtered, exp_smoothed. %%%%%%%%
  figure(2);
  subplot (2, 1, 1);

  plot(plot_values_(8,2:end)./1000, plot_values_(2,2:end), 'r','LineWidth',1, 
        plot_values_(8,2:end)./1000, plot_values_(3,2:end), 'linestyle', ':','k', 'LineWidth', 4, 
        plot_values_(8,2:end)./1000, plot_values_(4,2:end), 'k', 'LineWidth', 4);
        % plot extra travel time:
        % plot_values_(8,2:end)./1000, plot_values_(9,2:end), 'b', 'LineWidth', 2);

  title('Delay Signals', 'fontsize', 14);
  xlabel('time (s)', 'fontsize', 12);
  ylabel('signal (ms)', 'fontsize', 12);
  legend2 = legend ('Raw delay signal', 'Median filtered', 'Exp. smoothed');
  set (legend2, 'fontsize', 12);

  %%%%%%%% PLOT est_queuing_delay, loss_signal and congestion_signal. %%%%%%%%
  subplot (2, 1, 2);
  plot(plot_values_(8,2:end)./1000, plot_values_(5,2:end),'b','LineWidth',2, 
       plot_values_(8,2:end)./1000, kPacketLossPenaltyMs * plot_values_(6,2:end),'r', 'LineWidth',2,
       plot_values_(8,2:end)./1000, plot_values_(7,2:end),'k', 'LineWidth',4);

  title('Congestion Control Signals', 'fontsize', 14);
  xlabel('time (s)', 'fontsize', 12);
  ylabel('signal (ms)', 'fontsize', 12);
  legend3 = legend ('Est. queuing delay', 'Loss signal', 'Congestion signal');
  set (legend3, 'fontsize', 12);

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%