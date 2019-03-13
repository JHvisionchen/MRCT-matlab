function lf = lap(xf, yf, sigma)

	
	N = size(xf,1) * size(xf,2);
	xx = xf(:)' * xf(:) / N;  %squared norm of x
	yy = yf(:)' * yf(:) / N;  %squared norm of y
	
	%cross-correlation term in Fourier domain
	xyf = xf .* conj(yf);
	xy = sum(real(ifft2(xyf)), 3);  %to spatial domain
	
    w = exp(-1 / sigma^2 * max(0, (xx + yy - 2 * xy) / numel(xf)));
	%calculate gaussian response for all positions, then go back to the
	%Fourier domain
    l = -w;
    l(1, 1) = sum(w(:)) - l(1, 1);
	lf = fft2(l);
    

end

