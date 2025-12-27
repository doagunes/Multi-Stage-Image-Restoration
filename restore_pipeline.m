function restored = restore_pipeline(deg)
% restore_pipeline (V6)
% ------------------------------------------------------------
% Single pipeline for ALL images.
% Uses ONLY degraded image statistics for adaptive parameters.
%
% Required steps (in pipeline):
%  - Median Filtering (medfilt2)
%  - Wiener Filtering (wiener2)
%  - NLM (imnlmfilt) adaptively (texture-rich preservation)
%  - Unsharp masking (imsharpen)
%
% Design goals:
%  - Avoid ringing / deconvolution artifacts (no deconv)
%  - Prevent PSNR collapse on flat images (cameraman-safe)
%  - Keep texture images (barbara/baboon) from becoming patchy
% ------------------------------------------------------------

% ---------- Normalize ----------
if ~isa(deg,"double"), deg = im2double(deg); end
deg = min(max(deg,0),1);
if ndims(deg)==3, deg = rgb2gray(deg); end

% ---------- Noise analysis (MAD Laplacian) ----------
L = [0 1 0; 1 -4 1; 0 1 0];
lap = imfilter(deg, L, "replicate");
sigma_n = median(abs(lap(:))) / 0.6745;
sigma_n = max(1e-6, sigma_n);
noiseVar = sigma_n^2;

% Impulse ratio (salt & pepper proxy)
tmp = imgaussfilt(deg, 0.5);
impRatio = mean(tmp(:) < 0.02 | tmp(:) > 0.98);

% ---------- Stage 1: Median filter (required) ----------
% Keep median fixed 3x3 (stable & comparable). If you want,
% you can make this adaptive but I'm keeping it conservative.
s1 = medfilt2(deg, [3 3], "symmetric");

% ---------- Stage 2: Wiener filter (required) ----------
if min(size(s1)) >= 512
    wsize = [7 7];
else
    wsize = [5 5];
end
s2 = wiener2(s1, wsize);
s2 = min(max(s2,0),1);

% ---------- Texture / flatness analysis (from degraded only) ----------
% Use gradient energy + Laplacian variance to detect texture richness.
G = imgradient(s2);
gMean = mean(G(:));
lapVar = var(imfilter(s2, L, "replicate"), 0, "all");
lapVar = max(1e-12, lapVar);

% Normalize to [0,1] roughly (dataset-dependent but bounded)
texScore = min(max( (gMean/0.12) + (lapVar*8000), 0), 2); % ~0..2
texScore = texScore / 2;  % 0..1

% ---------- Stage 3: NLM (required, but SAFE) ----------
% Problem we had: NLM caused patchy artifacts (barbara) when too strong.
% Solution:
% - Keep NLM mild by bounding DegreeOfSmoothing
% - Use it more when texture is high, less when flat
%
% DegreeOfSmoothing should be in variance units for imnlmfilt.
% We'll base it on noiseVar but heavily bounded.
degSmooth_base = (0.7*sigma_n)^2;         % noise-driven
degSmooth_base = min(max(degSmooth_base, 1e-6), 0.004);  % tight bound

% Apply *less* smoothing on textured images (to avoid patchiness),
% *more* on flat images (to improve PSNR).
degSmooth = degSmooth_base * (1.2 - 0.7*texScore);  % tex high -> smaller smoothing
degSmooth = min(max(degSmooth, 1e-6), 0.004);

try
    s3 = imnlmfilt(s2, ...
        "DegreeOfSmoothing", degSmooth, ...
        "SearchWindowSize", 21, ...
        "ComparisonWindowSize", 7);
catch
    s3 = s2;
end
s3 = min(max(s3,0),1);

% Optional: if impulse ratio is high, a tiny post-clean helps PSNR
if impRatio > 0.05
    s3 = wiener2(s3, [3 3]);
    s3 = min(max(s3,0),1);
end

% ---------- Stage 4: Unsharp masking (required) ----------
% Key: avoid sharpening noise / flat areas (cameraman-safe).
% We'll compute an edge mask from gradient magnitude and sharpen mostly edges.
G2 = imgradient(s3);
gMax = max(G2(:)) + 1e-9;
edgeMask = (G2 / gMax) .^ 0.8;   % emphasize edges
edgeMask = min(max(edgeMask,0),1);

% Amount: increase slightly with blur proxy, decrease with noise.
blurStrength = 1 / (1 + 8000*lapVar);  % higher => blurrier
noiseStrength = 1 / (1 + 80*sigma_n);  % lower when noisier

amount = 0.10 + 0.25*blurStrength*noiseStrength;  % ~[0.10,0.35]
amount = min(max(amount, 0.10), 0.30);

% Sharpen base output (full) but with higher threshold to avoid noise
sharp = imsharpen(s3, ...
    "Radius", 1.0, ...
    "Amount", amount, ...
    "Threshold", 0.06);  % protect flat/noisy areas
sharp = min(max(sharp,0),1);

% Edge-only blend: keep flats closer to s3 (PSNR-safe)
s4 = s3 .* (1-edgeMask) + sharp .* edgeMask;
s4 = min(max(s4,0),1);

% ---------- Stage 5: Tone stabilization (PSNR guard) ----------
% Match mean/std to s3 (denoised reference) to prevent drift.
mRef = mean(s3(:));  sRef = std(s3(:));
m4 = mean(s4(:));    s4std = std(s4(:));

if s4std > 1e-6
    s5 = (s4 - m4) * (sRef/(s4std + 1e-9)) + mRef;
else
    s5 = s3;
end
s5 = min(max(s5,0),1);

% ---------- Stage 6: Mild contrast (safe) ----------
% Very mild stretch; avoids CLAHE artifacts.
lims = stretchlim(s5, [0.01 0.99]);
restored = imadjust(s5, lims, []);
restored = min(max(restored,0),1);

end
