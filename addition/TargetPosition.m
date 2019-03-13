function  pos = TargetPosition(pos,response,zf,cell_size)

%target location is at the maximum response. we must take into
%account the fact that, if the target doesn't move, the peak
%will appear at the top-left corner, not at the center (this is
%discussed in the paper). the responses wrap around cyclically.

[vert_delta, horiz_delta] = find(response == max(response(:)), 1);
			if vert_delta > size(zf,1) / 2,  %wrap around to negative half-space of vertical axis
				vert_delta = vert_delta - size(zf,1);
			end
			if horiz_delta > size(zf,2) / 2,  %same for horizontal axis
				horiz_delta = horiz_delta - size(zf,2);
			end
			pos = pos + cell_size * [vert_delta - 1, horiz_delta - 1];
        end


