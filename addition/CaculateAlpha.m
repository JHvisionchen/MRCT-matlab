function  [ alpha1f,alpha2f ] = CaculateAlpha(zf,model,yf,config)

        kf_xx = gaussian_correlation(model.xf, model.xf, config.kernel.sigma);
        kf_xz = gaussian_correlation(zf, model.xf, config.kernel.sigma);  % kxz
        kf_zz = gaussian_correlation(zf, zf,config.kernel.sigma);  % kzz
        lf_xx = LaplasseMatrix(model.xf, model.xf, config.kernel.sigma); 
        lf_xz = LaplasseMatrix(zf, model.xf, config.kernel.sigma); %laplace matrix lxz
        lf_zz = LaplasseMatrix(zf, zf, config.kernel.sigma); % lzz
        
        % 
        m = numel(yf);
        delta = config.lambda * m;
        eta = config.gama/(4*m);
        
        % q1,q2,q3,q4
        q1f = eta * lf_xx .* kf_xx + eta * lf_xz .* kf_xz + delta + kf_xx;
        q2f = eta * lf_xx .* kf_xz + eta * lf_xz .* kf_zz + kf_xz;
        q3f = eta * lf_xz .* kf_xx + eta * lf_zz .* kf_xz;
        q4f = eta * lf_xz .* kf_xz + eta * lf_zz .* kf_zz + delta;
        
        % equation for fast training
        constant = q1f .* q4f - q3f .* q2f;
        alpha1f = q4f .* yf ./ constant;
        alpha2f = -q3f .* yf ./ constant;

end

