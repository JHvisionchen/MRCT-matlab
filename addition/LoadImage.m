function  [im,im_gray] = LoadImage( video_path,img_files,frame ,resize_image)
        % load image
		im = imread([video_path img_files{frame}]);
		if size(im,3) > 1,
			im_gray = rgb2gray(im);
        else 
            im_gray = im;
		end
          
		if resize_image,
			im = imresize(im, 0.5);
            im_gray = imresize(im_gray,0.5);
        end

end

