%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Equivalent to bwe_simulation_framework DelayFilter.
function delayed_packets = AddPathDelay(packets)
  kOneWayPathDelayMs = 50;
  delayed_packets = packets;
  delayed_packets(1,:) = kOneWayPathDelayMs + packets(1,:);
endfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%