%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RunNadaFilter (num_packets)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Constants.
  kCapacityKbps = 1500;
  kPacketLossPenaltyMs = 1000;
  kMinBitrateKbps = 50;
  kMaxBitrateKbps = 2500;
  kFeedbackIntervalMs = 100;
  kQueuingDelayUpperBoundMs = 10;
  kDerivativeUpperBound = 10 / kFeedbackIntervalMs;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Members, initial value.
  bitrate_kbps_ = 300;
  last_send_time_ms_ = 0;
  arrival_packets_ = [];
  % now, delay_signal, median_filtered, exp_smoothed, est_queuing_delay, loss_ratio, congestion_signal.
  feedbacks_ = [0; 0; 0; 0; 0; 0; 0];   
  baseline_delay_ms_ = 10000;  % Upper bound.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  for packet_id=1:num_packets
  
    % Generate packets one by one.
    new_packet = CreatePackets (1, kPayloadSizeBytes, bitrate_kbps_, packet_id-1, last_send_time_ms_);
    arrival_packet = ArrivalPackets (new_packet, kCapacityKbps);
    last_send_time_ms_ = new_packet(1,1);
    now_ms = arrival_packet(1,1);

    % Use delay as a signal.
    delay = arrival_packet(1,1) - new_packet(1,1);
    baseline_delay_ms_ = min (baseline_delay_ms_, delay);       
    delay_signal = delay - baseline_delay_ms_;                % 1) Subtract Baseline.
    median_filtered = MedianFilter (delay_signal);            % 2) Apply Median filter.
    exp_smoothed = ExpSmoothingFilter(median_filtered);       % 3) Apply Exponential Smoothing Filter.
    est_queuing_delay_ms = NonLinearWarping(exp_smoothed);    % 4) Non-linear Estimate queuing delay warping.

    % Use loss as a signal.
    arrival_packets_ = [arrival_packets_ arrival_packet];
    loss_ratio = LossRatio(arrival_packets_);
    % Truncate stored packets to prevent it to be to large.
    if (size(arrival_packets_, 2) > 1000)
       arrival_packets_ = arrival_packets_(:,500:end);
    endif


    congestion_signal_ms = est_queuing_delay_ms + loss_ratio*kPacketLossPenaltyMs;

    % Generate and process feedback --- Update bitrate_kbps_.
    if (now_ms - feedbacks_(1,end) >= kFeedbackIntervalMs)
      delta_ms = now_ms - feedbacks_(1,end);
      derivative = (congestion_signal_ms - feedbacks_(7,end)) / delta_ms;
      
      % AcceleratedRampUp
      if (loss_ratio == 0 & est_queuing_delay_ms < kQueuingDelayUpperBoundMs & derivative < kDerivativeUpperBound)
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
    endif
    feedback = [now_ms; delay_signal; median_filtered; exp_smoothed; est_queuing_delay_ms; loss_ratio; congestion_signal];
    feedbacks_ = [feedbacks_ feedback];
  endfor

   
  kThreshold = 6.5*ones(1,num_packets);
  decision =  (exp_smoothed > kThreshold);

  plot(feedbacks_(2,:),'r','LineWidth',1, 
       feedbacks_(3,:), 'linestyle', ':','k', 'LineWidth', 4, 
       feedbacks_(4,:),'k', 'LineWidth',4,
       kThreshold, 'linestyle', '--', 'b', 'LineWidth',2,
       decision, 'b', 'LineWidth',3);

endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%