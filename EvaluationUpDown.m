% Maps [ending_time(s) capacity(kbps)]
function kCapacitiesKbps = EvaluationUpDown ()
	up = [20.2:0.2:40.2; 500:10:1500]';
	down = [60.4:0.2:80.4; 1500:-10:500]';
	kCapacitiesKbps = [20 500; up; 60 1500; down; 100 500];
endfunction