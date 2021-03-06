%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Receives a link capacity testbed configuration as input %%%%%%%%%%%%%%%%%%
function RunNada (kCapacitiesKbps)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Constant parameters.
  kPacketLossPenaltyMs = 1000.0;
  kPayloadSizeBytes = 1200.0;
  kMinBitrateKbps = 50.0;
  kMaxBitrateKbps = 2500.0;
  kFeedbackIntervalMs = 100.0;
  kQueuingDelayUpperBoundMs = 10.0;
  kDerivativeUpperBound = 10.0 / kFeedbackIntervalMs;
  kOriginalMode = true;
  kUsingMedianFilter = true;
  kRampDownEnabled = false;
  kEstimateOneWayPathDelay = false;
  kQueuingDelayUpperBoundMs = 10.0;
  kProportionalityDelayBits = 20.0;
  kMaxCongestionSignalMs = 50.0;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Simulation can be shorten in order to obtain results more quickly.
  % Convergence should take place before link capacity changes.
  time_compression = 1.0;  % Optional.
  kCapacitiesKbps (:,1) = kCapacitiesKbps (:,1)./time_compression;
  % Link capacity can be reduced to test a stressed scenario.
  reducing_factor = 1.0;  % Optional.
  kCapacitiesKbps (:,2) = kCapacitiesKbps (:,2)./reducing_factor;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Members, initial values.
  bitrate_kbps_ = 300.0;
  now_sender_ms_ = 0;
  now_receiver_ms_ = 0;
  last_send_time_ms_ = 0;
  arrival_packets_ = [];
  % now, congestion_signal.
  feedbacks_ = [0; 0];
  baseline_delay_ms_ = 10000.0;  % Upper bound.
  max_bitrate_kbps_ = 0; % Lower bound.
  % PLOT_VALUES: bitrate, delay_signal, median_filtered, exp_smoothed,
  % est_queuing_delay, loss_ratio, congestion_signal, time_ms, extra_delay.
  plot_values_ = zeros(9, 1);
  packet_id_ = 1;  % Sequential, starting at 1.
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

      if (kUsingMedianFilter)
        median_filtered = MedianFilter ([plot_values_(2,max(1,end-3):end) delay_signal])(end);
      else
        median_filtered = min ([plot_values_(2,max(1,end-28):end) delay_signal]);
      endif
      exp_smoothed = ExpSmoothingFilter([plot_values_(4,end) median_filtered])(2);
      est_queuing_delay_ms = NonLinearWarping(exp_smoothed);

      if (kEstimateOneWayPathDelay)
        if (est_queuing_delay_ms < kQueuingDelayUpperBoundMs)
          max_bitrate_kbps_ = max(max_bitrate_kbps_, bitrate_kbps_);
        endif
        estimated_one_way_path_delay_ms = baseline_delay_ms_ - 8*kPayloadSizeBytes/max_bitrate_kbps_;
        current_baseline_ms = estimated_one_way_path_delay_ms + 8*kPayloadSizeBytes/bitrate_kbps_;

        delay_signal = max(0, delay_signal + baseline_delay_ms_ - current_baseline_ms);
        median_filtered = max(0, median_filtered + baseline_delay_ms_ - current_baseline_ms);
        exp_smoothed = max(0, exp_smoothed + baseline_delay_ms_ - current_baseline_ms);
        est_queuing_delay_ms = max(0, est_queuing_delay_ms + baseline_delay_ms_ - current_baseline_ms);
      endif

      % Use loss as a signal.
      arrival_packets_ = [arrival_packets_ arrival_packet];
      loss_ratio = LossRatio(arrival_packets_);

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
          if (loss_ratio == 0 && (exp_smoothed < extra_delay_ms_ - kQueuingDelayUpperBoundMs || exp_smoothed < kQueuingDelayUpperBoundMs/3) &&
              derivative < kDerivativeUpperBound && receiving_rate > kMinBitrateKbps)
            kMaxRampUpQueuingDelayMs = 50;  % Referred as T_th.
            kGamma0 = 0.5;                  % Referred as gamma_0.
            kGamma = min(kGamma0, kMaxRampUpQueuingDelayMs/(baseline_delay_ms_ + kFeedbackIntervalMs));
            bitrate_kbps_ = (1.0 + kGamma) * receiving_rate;
          % New AcceleratedRampDown mode.
          elseif (kRampDownEnabled && (congestion_signal_ms > kMaxCongestionSignalMs
                  || exp_smoothed > kMaxCongestionSignalMs))
            kGamma0 = 0.9;
            my_gamma = 2.0 * kMaxCongestionSignalMs / (congestion_signal_ms + exp_smoothed);
            my_gamma = min(my_gamma, kGamma0);
            bitrate_kbps_ = kGamma0 * receiving_rate;
          % Smoothed GradualRateUpdate.
          else
            bitrate_reference = 3*(bitrate_kbps_- kMinBitrateKbps)/(kMaxBitrateKbps - kMinBitrateKbps);
            smoothing_factor = min(bitrate_reference ^ 2.0, 1.0);
            kTauOMs = 500.0;           % Referred as tau_o.
            kEta = 2.0;                % Referred as eta.
            kKappa = 1.0;              % Referred as kappa.
            kReferenceDelayMs = 10.0;  % Referred as x_ref.
            kPriorityWeight = 1.0;     % Referred as w.
            new_congestion_signal_ms = max(0, congestion_signal_ms - extra_delay_ms_);
            x_hat = new_congestion_signal_ms + kEta*kTauOMs*derivative;
            kTheta = kPriorityWeight * (kMaxBitrateKbps - kMinBitrateKbps) * kReferenceDelayMs;
            increase_kbps = kKappa*delta_ms*(kTheta - x_hat*(bitrate_kbps_ - kMinBitrateKbps)) / (kTauOMs^2);
            bitrate_kbps_ = bitrate_kbps_ + increase_kbps * smoothing_factor;
          endif
        endif
        % Bitrate should be kept between [kMin, kMax].
        bitrate_kbps_ = max(kMinBitrateKbps, min(kMaxBitrateKbps, bitrate_kbps_));
        feedback = [now_receiver_ms_; congestion_signal_ms];
        feedbacks_ = [feedbacks_ feedback];
      endif

      plot_value = [bitrate_kbps_; delay_signal; median_filtered; exp_smoothed;
                    est_queuing_delay_ms; loss_ratio; congestion_signal_ms;
                    now_receiver_ms_; extra_delay_ms_];
      plot_values_ = [plot_values_ plot_value];
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    endif

    packet_id_ = packet_id_ + 1;

  endwhile

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOT SIMULATION RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%% PLOT BITRATE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

  axis([0,30,0,2250]);

  %%%%%%%%%%%%%%%%%%%%%% PLOT signals on the same window %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%% PLOT delay_signal, median_filtered, exp_smoothed. %%%%%%%%%%%%%%
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
  if (kUsingMedianFilter)
    legend2 = legend ('Raw delay signal', 'Median filtered', 'Exp. smoothed');
  else
    legend2 = legend ('Raw delay signal', 'Min filtered', 'Exp. smoothed');
  endif
  set (legend2, 'fontsize', 12);

  axis([0,30,0,300]);

  %%%%%%%%%%%%%%%%%%%%%% PLOT est_queuing_delay, loss_signal and congestion_signal. %%%%%
  subplot (2, 1, 2);
  plot(plot_values_(8,2:end)./1000, plot_values_(5,2:end),'b','LineWidth',2,
       plot_values_(8,2:end)./1000, kPacketLossPenaltyMs * plot_values_(6,2:end),'r', 'LineWidth',2,
       plot_values_(8,2:end)./1000, plot_values_(7,2:end),'k', 'LineWidth',4);

  title('Congestion Control Signals', 'fontsize', 14);
  xlabel('time (s)', 'fontsize', 12);
  ylabel('signal (ms)', 'fontsize', 12);
  legend3 = legend ('Est. queuing delay', 'Loss signal', 'Congestion signal');
  set (legend3, 'fontsize', 12);

  axis([0,30,0,300]);

  %%%%%%%%%%%%%%%%%%%%%% PRINT Average Metrics (time weighted) %%%%%%%%%%%%%%%%%%%%%%%%%%

  average_bitrate_kbps = TimeWeightedAverage(plot_values_, 1)
  average_delay_ms = TimeWeightedAverage(plot_values_, 2)

  %%%%%%%%%%%%%%%%%%%%%% PRINT Global Packet Loss %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Sequence numbers are sequential, starting at one. Overflow won't happen for short simulations.

  global_packet_loss = 1.0 - size(plot_values_,2)/packet_id_

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
