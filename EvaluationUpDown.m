% Maps [ending_time(s) capacity(kbps)]
function kCapacitiesKbps = EvaluationUpDown ()
	up = [0.2:0.2:20.2; 500:10:1500]';
	down = [20.4:0.2:40.4; 1500:-10:500]';
	kCapacitiesKbps = [up; down];
endfunction