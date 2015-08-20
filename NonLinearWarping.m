%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function non_linear_warping = NonLinearWarping (value)

	kDelayMinMs = 50;   % Referred as d_th.
	kDelayMaxMs = 400;  % Referred as d_max.
	 
	if (value <= kDelayMinMs)
		non_linear_warping = value;
	elseif (value < kDelayMaxMs)
		non_linear_warping = kDelayMinMs*((kDelayMaxMs-value)/(kDelayMaxMs-kDelayMinMs))^4;
	else
		non_linear_warping = 0;
	endif
endfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%