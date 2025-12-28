function restored = restore_pipeline(deg)
% restore_pipeline (V7-METRIC)
% ------------------------------------------------------------
% PURPOSE: Push PSNR/MSE higher (even if texture fidelity drops).
% Required filters included:
%   - medfilt2
%   - wiener2
%   - imnlmfilt (more aggressive)
%   - imsharpen (very mild)
% No original used; parameters from degraded stats.
% ------------------------------------------------------------

if ~isa(deg,"double"), deg = im2double(deg); end
deg = min(max(deg,0),1);
if ndims(deg)==3, deg = rgb2gray(deg); end

% Noise estimate
L = [0 1 0; 1 -4 1; 0 1 0];
lap = imfilter(deg, L, "replicate");
sigma_n = median(abs(lap(:))) / 0.6745;
sigma_n = max(1e-6, sigma_n);

% Impulse proxy
tmp = imgaussfilt(deg, 0.5);
impRatio = mean(tmp(:) < 0.02 | tmp(:) > 0.98);

% 1) Median (adaptive window, helps impulse noise strongly)
if impRatio > 0.08
    medW = 7;
elseif impRatio > 0.03
    medW = 5;
else
    medW = 3;
end
s1 = medfilt2(deg, [medW medW], "symmetric");

% 2) Wiener (main denoise)
if min(size(s1)) >= 512
    wsize = [7 7];
else
    wsize = [5 5];
end
s2 = wiener2(s1, wsize);
s2 = min(max(s2,0),1);

% 3) NLM (AGGRESSIVE to boost PSNR)
% Increase DegreeOfSmoothing but keep it bounded.
degSmooth = (0.90*sigma_n)^2;
degSmooth = min(max(degSmooth, 2e-4), 3e-3);   % much higher than "safe" versions

s3 = imnlmfilt(s2, ...
    "DegreeOfSmoothing", degSmooth, ...
    "SearchWindowSize", 21, ...
    "ComparisonWindowSize", 7);
s3 = min(max(s3,0),1);

% Patchy stabilizer (very mild)
% (This is NOT CLAHE; it's just to reduce NLM blockiness.)
s3b = imgaussfilt(s3, 0.6);
s3b = min(max(s3b,0),1);

% 4) Unsharp masking (VERY mild so it doesn't hurt PSNR)
% Compute blur proxy to scale slightly.
lapVar = var(imfilter(s3b, L, "replicate"), 0, "all");
lapVar = max(1e-12, lapVar);
blurStrength = 1 / (1 + 8000*lapVar);

amount = 0.04 + 0.08*blurStrength;   % small range
amount = min(max(amount, 0.04), 0.10);

s4 = imsharpen(s3b, ...
    "Radius", 1.0, ...
    "Amount", amount, ...
    "Threshold", 0.10);              % high threshold => PSNR-friendly
s4 = min(max(s4,0),1);

% Final tiny Wiener to remove sharpen speckles
restored = wiener2(s4, [3 3]);
restored = min(max(restored,0),1);

end
