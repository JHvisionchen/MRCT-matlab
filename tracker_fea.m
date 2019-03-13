function [positions, time] = tracker_fea(video_path, img_files, pos, target_sz, config, show_visualization)

[resize_image,pos,target_sz] = ResizeImage(pos,target_sz);

im_sz = size(imread([video_path img_files{1}]));
[window_sz, app_sz ]= search_window(target_sz,im_sz, config);
config.window_sz = window_sz;
config.app_sz = app_sz;

config.detc = det_config(target_sz, im_sz);

cell_size = config.features.cell_size;
interp_factor = config.interp_factor;
output_sigma_factor = config.output_sigma_factor;

output_sigma = sqrt(prod(target_sz)) *output_sigma_factor / cell_size;
%% label
yf = fft2(gaussian_shaped_labels(output_sigma, floor(window_sz / cell_size)));
neg_labels_f = fft2(zeros(floor(window_sz / cell_size)));
pos_labels_f = yf;
un_labels_f = fft2(zeros(floor(window_sz / cell_size)));

cos_window = hann(size(yf,1)) * hann(size(yf,2))';	 

app_yf = fft2(gaussian_shaped_labels(output_sigma, floor(app_sz / cell_size)));
app_neg_labels_f = fft2(zeros(floor(app_sz / cell_size)));
app_pos_labels_f = app_yf;
app_un_labels_f = fft2(zeros(floor(app_sz / cell_size)));

time = 0;  %to calculate FPS
positions = zeros(numel(img_files), 2);  %to calculate precision
%% generate negative base samples
stepdis = [-1 0];
nsample_pos = 1;
nsample_neg = size(stepdis, 1);
nsample = nsample_pos + nsample_neg;
displace = repmat(window_sz, [nsample_neg, 1]) .* stepdis;


gamma = config.gama;
lambda = config.lambda;
Jn = blkdiag(eye(nsample), zeros(1));
tempm = numel(yf) * nsample;
eta = gamma / (4 * tempm);
delta = lambda * tempm;
tempm = numel(app_yf) * nsample;
app_eta = gamma / (4 * tempm);
app_delta = lambda * tempm;

config.cos_window = cos_window;
config.app_pos_labels_f = app_pos_labels_f;
config.app_neg_labels_f = app_neg_labels_f;
config.app_un_labels_f = app_un_labels_f;
config.nsample = nsample;
config.nsample_pos = nsample_pos;
config.Jn = Jn;
config.app_eta = app_eta;
config.app_delta = app_delta;
config.target_sz = target_sz;

for frame = 1:numel(img_files),
    % load image
    [im, im_gray] = LoadImage( video_path,img_files,frame ,resize_image);
    
    tic()
    %% next frame
    if frame > 1
        %% compute motion_model alpha_bar
        sample_patch = get_subwindow(im, pos, window_sz);
        sample_zf =  fft2(get_features_new(sample_patch, config, cos_window));
        sample_f = cat(4, motion_model.xf, sample_zf);
        [s1, s2, ~, n] = size(sample_f);
        sample_kf = zeros(n, n, s1, s2);
        sample_lf = zeros(n, n, s1, s2);
        for i = 1:n
            for j = 1:n
                sample_kf(i, j, :, :) = gaussian_correlation(sample_f(:, :, :, i), sample_f(:, :, :, j),config.kernel.sigma);
                sample_lf(i, j, :, :) = lap(sample_f(:, :, :, i), sample_f(:, :, :, j), config.kernel.sigma);
            end
        end
        
        alpha_bar = zeros(s1, s2, nsample+1);
        Y_bar = zeros(n, 1);
        for f1 = 1:s1
            for f2 = 1:s2
                Y_bar(:) = un_labels_f(f1, f2);
                Y_bar(1:nsample_pos) = pos_labels_f(f1, f2);
                Y_bar(nsample_pos+1:nsample) = neg_labels_f(f1, f2);
                K_bar = (sample_kf(:, :, f1, f2));
                L_bar = (sample_lf(:, :, f1, f2));
                alpha_bar(f1, f2, :) = (Jn * K_bar +  delta * eye(size(K_bar)) + eta * L_bar * K_bar)\Y_bar;
            end
        end

        
        if frame == 2
            motion_model.alpha_bar = alpha_bar;
        else
            motion_model.alpha_bar = (1 - interp_factor) * motion_model.alpha_bar + interp_factor * alpha_bar;
        end
        
        %% location with motion model
        model_permutealpha_bar = permute(motion_model.alpha_bar, [3, 1, 2]);
        [s1, s2, ~, ~] = size(sample_f);
        sample_response = zeros(s1, s2);
        for f1 =1:s1
            for f2 = 1:s2
                K_bar = (sample_kf(:, nsample+1:end, f1, f2));
                sample_response(f1, f2) = K_bar' * model_permutealpha_bar(:, f1, f2);
            end
        end
        response = real(ifft2(sample_response));
        [vert_delta, horiz_delta] = find(response == max(response(:)), 1);
        if vert_delta > size(sample_zf,1) / 2,  %wrap around to negative half-space of vertical axis
            vert_delta = vert_delta - size(sample_zf,1);
        end
        if horiz_delta > size(sample_zf,2) / 2,  %same for horizontal axis
            horiz_delta = horiz_delta - size(sample_zf,2);
        end
        pos = pos + cell_size * [vert_delta - 1, horiz_delta - 1];
        

       
    end
    
    %%  collect labeled samples
    sample_patch = get_subwindow(im, pos, window_sz);
    possample_xf =  fft2(get_features_new(sample_patch, config, cos_window));
    negsample_pos = repmat(pos, [nsample_neg, 1]) + displace;
    for i  = 1:nsample_neg
        sample_patch = get_subwindow(im, negsample_pos(i, :), window_sz);
        negsample_xf(:, :, :, i) =  fft2(get_features_new(sample_patch,config, cos_window));
    end
     
    
    if frame == 1
        possample_model_xf = possample_xf;
        negsample_model_xf = negsample_xf;
        motion_model.xf = cat(4, possample_model_xf, negsample_model_xf);
    else
        possample_model_xf = (1 - interp_factor) * possample_model_xf + interp_factor * possample_xf;
        negsample_model_xf = (1 - interp_factor) * negsample_model_xf + interp_factor * negsample_xf;
        motion_model.xf = cat(4, possample_model_xf, negsample_model_xf);
    end
    
    % save position and timing
    positions(frame,:) = pos;
    time = time + toc();
    %visualization
    if show_visualization,
        box = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
        if frame == 1,  %first frame, create GUI
            figure('Number','off', 'Name',['Tracker - ' video_path]);
            im_handle = imshow(uint8(im), 'Border','tight', 'InitialMag', 100 + 100 * (length(im) < 500));
            rect_handle = rectangle('Position',box, 'EdgeColor','g');
            text_handle = text(10, 10, int2str(frame));
            set(text_handle, 'color', [0 1 1]);
        else
            try  %subsequent frames, update GUI
                set(im_handle, 'CData', im)
                set(rect_handle, 'Position', box)
                set(text_handle, 'string', int2str(frame));
            catch
                return
            end
        end
        drawnow
    end
end

if resize_image,
    positions = positions * 2;
end

end
