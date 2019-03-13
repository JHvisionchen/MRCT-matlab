function [resize_image,pos,target_sz] = ResizeImage(pos,target_sz)
	%if the target is large, lower the resolution, we don't need that much detail
	resize_image = (sqrt(prod(target_sz)) >= 100);  % diagonal size >= threshold
	if resize_image,
		pos = floor(pos / 2);
		target_sz = floor(target_sz / 2);
	end


end

