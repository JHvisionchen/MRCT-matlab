function [pos, max_response] = refine_pos_rf(im, pos, svm_struct, app_model, config)

max_response=config.max_response;
window_sz=config.window_sz;
app_sz=config.app_sz;

% cell_size=config.features.cell_size;
% config.label_prior_sigma = 15;

[feat, pos_samples, ~, weights]=det_samples(im, pos, window_sz, config.detc);

% [hs,probs] = fernsClfApply( feat', ferns);

scores=svm_struct.w'*feat+svm_struct.b;
scores=scores.*reshape(weights,1,[]);
tpos=round(pos_samples(:, find(scores==max(scores),1)));
if isempty(tpos)
%     disp('empty');
    return;
end
tpos=reshape(tpos,1,[]);
% figure(2), imshow(im),
% hold on, plot(tpos(2), tpos(1), 'xg');

% if size(im,3)>1
%     im=rgb2gray(im);
% end


%% 计算alpha_bar
cell_size = config.features.cell_size;
sample_patch = get_subwindow(im, tpos, app_sz);
sample_zf =  fft2(get_features_new(sample_patch, config, []));

sample_f = cat(4, app_model.xf, sample_zf);
[s1, s2, ~, n] = size(sample_f);
sample_kf = zeros(n, n, s1, s2);
sample_lf = zeros(n, n, s1, s2);
for i = 1:n
    for j = 1:n
        sample_kf(i, j, :, :) = gaussian_correlation(sample_f(:, :, :, i), sample_f(:, :, :, j),config.kernel.sigma);
        sample_lf(i, j, :, :) = lap(sample_f(:, :, :, i), sample_f(:, :, :, j), config.kernel.sigma);
    end
end

app_alpha_bar = zeros(s1, s2,config.nsample+1);
Y_bar = zeros(n, 1);
for f1 = 1:s1
    for f2 = 1:s2
        Y_bar(:) = config.app_un_labels_f(f1, f2);
        Y_bar(1:config.nsample_pos) = config.app_pos_labels_f(f1, f2);
        Y_bar(config.nsample_pos + 1:config.nsample) = config.app_neg_labels_f(f1, f2);
        K_bar = (sample_kf(:, :, f1, f2));
        L_bar = (sample_lf(:, :, f1, f2));
        app_alpha_bar(f1, f2, :) = (config.Jn * K_bar +  config.app_delta * eye(size(K_bar)) + config.app_eta * L_bar * K_bar)\Y_bar;
    end
end

alpha_bar = (1 - config.interp_factor) * app_model.alpha_bar + config.interp_factor * app_alpha_bar;
% % response = real(ifft2(model.alpha1f .* kf_xz + model.alpha2f .* kf_zz));
model_permutealpha_bar = permute(alpha_bar, [3, 1, 2]);
[s1, s2, ~, ~] = size(sample_f);
sample_response = zeros(s1, s2);
for f1 =1:s1
    for f2 = 1:s2
        K_bar = (sample_kf(:, config.nsample+1:end, f1, f2));
        sample_response(f1, f2) = K_bar' * model_permutealpha_bar(:, f1, f2);
    end
end
response = real(ifft2(sample_response));
max_response = max(response(:));
tpos = TargetPosition(tpos,response,sample_zf,cell_size);
%%%%%%%%%%%%%%%%%%%%%%%%%
%*********更改部分******************

 disp(['enter redetec....' num2str(max_response)]);
if max_response>1.5*config.max_response && max(scores)>0
% if max_response>config.appearance_thresh && max(scores)>0
    pos = tpos;
elseif pos(1) < -config.target_sz(1) || pos(2) < -config.target_sz(2)
    pos = tpos;
else
    max_response = config.max_response;
end