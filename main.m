clc; clear; close all;

names = ["baboon","barbara","boat","cameraman","peppers"];

% Ensure output folder exists
if ~exist("results", "dir")
    mkdir("results");
end

results = cell(length(names), 7);
results = cell2table(results, "VariableNames", ...
    ["Image","MSE_Degraded","PSNR_Degraded","SSIM_Degraded","MSE_Restored","PSNR_Restored","SSIM_Restored"]);

for i = 1:length(names)
    name = names(i);

    origPath = "images/original_" + name + ".png";
    degPath  = "images/degraded_" + name + ".png";

    orig = imread(origPath);
    deg  = imread(degPath);

    % Convert to grayscale if needed
    if ndims(orig) == 3, orig = rgb2gray(orig); end
    if ndims(deg)  == 3, deg  = rgb2gray(deg);  end

    origD = im2double(orig);
    degD  = im2double(deg);

    % Normalize/clamp
    origD = min(max(origD, 0), 1);
    degD  = min(max(degD, 0), 1);

    % If size mismatch, align degraded to original for fair metrics
    if ~isequal(size(origD), size(degD))
        degD = imresize(degD, size(origD));
    end

    restoredD = restore_pipeline(degD);
    restoredD = min(max(restoredD, 0), 1);

    [mseD, psnrD, ssimD] = metrics(origD, degD);
    [mseR, psnrR, ssimR] = metrics(origD, restoredD);

    results{i, :} = {name, mseD, psnrD, ssimD, mseR, psnrR, ssimR};

    imwrite(restoredD, "results/restored_" + name + ".png");

    figure("Name", name);
    montage({origD, degD, restoredD}, "Size", [1 3]);
    title(name + " | Original - Degraded - Restored");
end

disp(results);
writetable(results, "results/metrics_table.csv");
