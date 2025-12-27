function [mseVal, psnrVal, ssimVal] = metrics(ref, img)
% metrics: MSE, PSNR, SSIM for double images in [0,1]

if ~isa(ref, "double"), ref = im2double(ref); end
if ~isa(img, "double"), img = im2double(img); end

ref = min(max(ref, 0), 1);
img = min(max(img, 0), 1);

% If size mismatch, resize img to ref (keeps evaluation consistent)
if ~isequal(size(ref), size(img))
    img = imresize(img, size(ref));
end

diff = ref - img;
mseVal = mean(diff(:).^2);

% For double images in [0,1], peak value = 1
psnrVal = psnr(img, ref, 1);

% SSIM
ssimVal = ssim(img, ref);

end
