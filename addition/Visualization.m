function Visualization(show_visualization,update_visualization,pos,target_sz,frame)
        %visualization
		if show_visualization,
			box = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
			stop = update_visualization(frame, box);
			if stop, break, end   %user pressed Esc, stop early
	    	drawnow
        % pause(0.05)  %uncomment to run slower
        end
        
    end



