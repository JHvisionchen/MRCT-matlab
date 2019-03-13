function x = get_features_new(imrgb, config, cos_window)
%GET_FEATURES
%   Extracts dense features from image.
[~, ~, n] = size(imrgb);
cell_size=config.features.cell_size;
nwindow=config.features.window_size;
nbins=config.features.nbins;
if n == 1
    im = imrgb;
    %HOG features, from Piotr's Toolbox
    x = double(fhog(single(im) / 255, cell_size, config.features.hog_orientations));
    x(:,:,end) = [];  %remove all-zeros channel ("truncation feature")
    
    % pixel intensity histogram, from Piotr's Toolbox
    h1=histcImWin(im,nbins,ones(nwindow,nwindow),'same');
    h1=h1(cell_size:cell_size:end,cell_size:cell_size:end,:);
    
    % intensity ajusted hitorgram
    
    im= 255-calcIIF(im,[cell_size,cell_size],32);
    h2=histcImWin(im,nbins,ones(nwindow,nwindow),'same');
    h2=h2(cell_size:cell_size:end,cell_size:cell_size:end,:);
    
    x=cat(3,x,h1,h2);
elseif n == 3
    im = rgb2gray(imrgb);
    %%HOG features, from Piotr's Toolbox
    x = double(fhog(single(im) / 255, cell_size, config.features.hog_orientations));
    x(:,:,end) = [];  %remove all-zeros channel ("truncation feature")
    
 
    
    
    %% pixel intensity histogram, from Piotr's Toolbox
    h1=histcImWin(im,nbins,ones(nwindow,nwindow),'same');
    h1=h1(cell_size:cell_size:end,cell_size:cell_size:end,:);
    
     imlab = uint8((RGB2Lab(imrgb) * 255));
     %% intensity ajusted hitorgram
    iml = 255-calcIIF(imlab(:,:,1),[cell_size,cell_size],32);
    h2 = histcImWin(iml,nbins,ones(nwindow,nwindow),'same');
    h2 = h2(cell_size:cell_size:end,cell_size:cell_size:end,:);
    
    ima = 255-calcIIF(imlab(:,:,2),[cell_size,cell_size],32);
    ha = histcImWin(ima,nbins,ones(nwindow,nwindow),'same');
    ha = ha(cell_size:cell_size:end,cell_size:cell_size:end,:);
    
    imb = 255-calcIIF(imlab(:,:,3),[cell_size,cell_size],32);
    hb = histcImWin(imb,nbins,ones(nwindow,nwindow),'same');
    hb = hb(cell_size:cell_size:end,cell_size:cell_size:end,:);
   
    %     x=cat(3,x,h1,h2);
   %x=cat(3,x, h1, h2, ha, hb);
   x=cat(3,x, h1, h2, ha, hb);
%    x = h2;
%     x=cat(3, rgbhist1, rgbhist2, rgbhist3);
elseif n > 3
    im = imrgb(:,:, 1);
    %HOG features, from Piotr's Toolbox
    x = double(fhog(single(im) / 255, cell_size, config.features.hog_orientations));
    x(:,:,end) = [];  %remove all-zeros channel ("truncation feature")
    
    % pixel intensity histogram, from Piotr's Toolbox
    h1=histcImWin(im,nbins,ones(nwindow,nwindow),'same');
    h1=h1(cell_size:cell_size:end,cell_size:cell_size:end,:);
    
    % intensity ajusted hitorgram
    
    im= 255-calcIIF(im,[cell_size,cell_size],32);
    h2=histcImWin(im,nbins,ones(nwindow,nwindow),'same');
    h2=h2(cell_size:cell_size:end,cell_size:cell_size:end,:);
end




%%process with cosine window if needed
if ~isempty(cos_window),
    x = bsxfun(@times, x, cos_window);
end

end

