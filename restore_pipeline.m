function restored = restore_pipeline(deg)
% restore_pipeline (V8-METRIC with Gaussian Stage)
% ------------------------------------------------------------
% PURPOSE: Push PSNR/MSE higher with added Gaussian filtering stage. 
% Required filters included: 
%   - medfilt2        (Stage 1: Impulse noise)
%   - imgaussfilt     (Stage 2: Gaussian noise) [NEW]
%   - wiener2         (Stage 3: Adaptive denoising)
%   - imnlmfilt       (Stage 4: Non-local means)
%   - imsharpen       (Stage 5: Edge enhancement)
% No original used; parameters from degraded stats. 
% ------------------------------------------------------------

if ~isa(deg,"double"), deg = im2double(deg); end
deg = min(max(deg,0),1);
if ndims(deg)==3, deg = rgb2gray(deg); end

% Noise estimate using Laplacian
L = [0 1 0; 1 -4 1; 0 1 0];
lap = imfilter(deg, L, "replicate");
sigma_n = median(abs(lap(: ))) / 0.6745;
sigma_n = max(1e-6, sigma_n);

% Impulse proxy
tmp = imgaussfilt(deg, 0.5);
impRatio = mean(tmp(:) < 0.02 | tmp(:) > 0.98);

% ============================================================
% STAGE 1: Median Filter (Impulse Noise Removal)
% ============================================================
if impRatio > 0.08
    medW = 7;
elseif impRatio > 0.03
    medW = 5;
else
    medW = 3;
end
s1 = medfilt2(deg, [medW medW], "symmetric");

% ============================================================
% STAGE 2: Gaussian Filter (Gaussian Noise Reduction) [NEW]
% ============================================================
% Adaptive sigma based on estimated noise level
gaussSigma = 0.5 + 2.0 * sigma_n;  % Scale with noise estimate
gaussSigma = min(max(gaussSigma, 0.5), 1.5);  % Bound to [0.5, 1.5]

s2 = imgaussfilt(s1, gaussSigma);
s2 = min(max(s2,0),1);

% ============================================================
% STAGE 3: Wiener Filter (Adaptive Denoising)
% ============================================================
if min(size(s2)) >= 512
    wsize = [7 7];
else
    wsize = [5 5];
end
s3 = wiener2(s2, wsize);
s3 = min(max(s3,0),1);

% ============================================================
% STAGE 4: Non-Local Means Filter (Self-Similarity Denoising)
% ============================================================
degSmooth = (0.90*sigma_n)^2;
degSmooth = min(max(degSmooth, 2e-4), 3e-3);

s4 = imnlmfilt(s3, ... 
    "DegreeOfSmoothing", degSmooth, ...
    "SearchWindowSize", 21, ...
    "ComparisonWindowSize", 7);
s4 = min(max(s4,0),1);

% Patchy stabilizer (very mild)
s4b = imgaussfilt(s4, 0.6);
s4b = min(max(s4b,0),1);

% ============================================================
% STAGE 5: Unsharp Masking (Edge Enhancement)
% ============================================================
lapVar = var(imfilter(s4b, L, "replicate"), 0, "all");
lapVar = max(1e-12, lapVar);
blurStrength = 1 / (1 + 8000*lapVar);

amount = 0.04 + 0.08*blurStrength;
amount = min(max(amount, 0.04), 0.10);

s5 = imsharpen(s4b, ... 
    "Radius", 1.0, ...
    "Amount", amount, ...
    "Threshold", 0.10);
s5 = min(max(s5,0),1);

% Final tiny Wiener to remove sharpen speckles
restored = wiener2(s5, [3 3]);
restored = min(max(restored,0),1);

end