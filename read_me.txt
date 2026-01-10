================================================================================
                    MULTI-STAGE IMAGE RESTORATION PROJECT
                         CE490 - Image Processing
                           Fall 2025-26 Final Project
================================================================================

Group 13
--------
- Doğa Güneş (20210602009)
- Benhur Rahman Okur (20220602059)

Instructor: Mehmet Türkan

================================================================================
                              PROJECT DESCRIPTION
================================================================================

This project implements a five-stage image restoration pipeline for enhancing
degraded images. The pipeline consists of:

    Stage 1: Median Filter      - Removes impulse (salt-and-pepper) noise
    Stage 2: Gaussian Filter    - Reduces Gaussian noise
    Stage 3: Wiener Filter      - Adaptive denoising based on local statistics
    Stage 4: Non-Local Means    - Self-similarity based denoising
    Stage 5: Unsharp Masking    - Edge enhancement

================================================================================
                               REQUIREMENTS
================================================================================

Software Requirements:
----------------------
    - MATLAB R2019b or later (recommended:  R2023a+)
    - Image Processing Toolbox (REQUIRED)

To check if Image Processing Toolbox is installed, run in MATLAB:
    >> ver('images')

================================================================================
                              FILE STRUCTURE
================================================================================

Multi-Stage-Image-Restoration/
│
├── main.m                  % Main script - RUN THIS FILE
├── restore_pipeline.m      % Five-stage restoration pipeline function
├── metrics. m               % Quality metrics calculation (MSE, PSNR, SSIM)
│
├── images/                 % Input images folder
│   ├── original_baboon.png
│   ├── original_barbara.png
│   ├── original_boat. png
│   ├── original_cameraman.png
│   ├── original_peppers. png
│   ├── degraded_baboon.png
│   ├── degraded_barbara.png
│   ├── degraded_boat.png
│   ├── degraded_cameraman.png
│   └── degraded_peppers.png
│
├── results/                % Output folder (created automatically)
│   ├── restored_baboon.png
│   ├── restored_barbara.png
│   ├── restored_boat.png
│   ├── restored_cameraman.png
│   ├── restored_peppers.png
│   └── metrics_table.csv
│
└── read_me.txt              % This file

================================================================================
                             HOW TO RUN THE CODE
================================================================================

STEP 1: Download/Clone the Repository
--------------------------------------
    Option A - Download ZIP:
        1. Go to:  https://github.com/doagunes/Multi-Stage-Image-Restoration
        2. Click "Code" button -> "Download ZIP"
        3. Extract the ZIP file to your desired location

    Option B - Git Clone:
        >> git clone https://github.com/doagunes/Multi-Stage-Image-Restoration.git

STEP 2: Open MATLAB
-------------------
    1. Launch MATLAB
    2. Navigate to the project folder using one of these methods:
       - Use the "Browse for Folder" button in MATLAB
       - Or type in Command Window: 
         >> cd 'C:\path\to\Multi-Stage-Image-Restoration'

STEP 3: Verify Current Directory
--------------------------------
    Make sure you are in the correct folder:
        >> pwd
    
    This should show the path to "Multi-Stage-Image-Restoration" folder. 
    
    Verify files exist:
        >> dir
    
    You should see:  main.m, restore_pipeline.m, metrics.m, images/, results/

STEP 4: Run the Main Script
---------------------------
    In MATLAB Command Window, type:
        >> main

    OR double-click "main.m" in the Current Folder panel and press F5 (Run)

STEP 5: Wait for Processing
---------------------------
    The script will: 
    1. Load each test image pair (original + degraded)
    2. Apply the five-stage restoration pipeline
    3. Calculate quality metrics (MSE, PSNR, SSIM)
    4. Display comparison figures (Original - Degraded - Restored)
    5. Save restored images to 'results/' folder
    6. Save metrics to 'results/metrics_table.csv'

    Processing time:  Approximately 1-3 minutes depending on your system. 

================================================================================
                              EXPECTED OUTPUT
================================================================================

Console Output:
---------------
    After running, you will see a table like this:

    Image       MSE_Degraded  PSNR_Degraded  SSIM_Degraded  MSE_Restored  PSNR_Restored  SSIM_Restored
    ________    ____________  _____________  _____________  ____________  _____________  _____________
    baboon      0.0223        16.52          0.157          0.0091        20.43          0.355
    barbara     0.0197        17.05          0.157          0.0052        22.83          0.597
    boat        0.0173        17.63          0.173          0.0038        24.25          0.602
    cameraman   0.0195        17.09          0.163          0.0063        22.02          0.645
    peppers     0.0164        17.86          0.138          0.0011        29.63          0.827

Figure Windows:
---------------
    5 figure windows will open, each showing a montage of: 
    [Original Image] - [Degraded Image] - [Restored Image]

Output Files (in 'results/' folder):
------------------------------------
    - restored_baboon. png
    - restored_barbara. png
    - restored_boat. png
    - restored_cameraman.png
    - restored_peppers.png
    - metrics_table.csv

================================================================================
                           FUNCTION DESCRIPTIONS
================================================================================

main.m
------
    Purpose: Main execution script
    - Loads original and degraded image pairs
    - Calls restore_pipeline() for each image
    - Computes and displays quality metrics
    - Saves results to disk

restore_pipeline.m
------------------
    Purpose: Five-stage image restoration
    Input:   Degraded image (grayscale, double precision)
    Output:  Restored image (grayscale, double precision)
    
    Stages:
        1. medfilt2()    - Median filtering (adaptive window:  3x3 to 7x7)
        2. imgaussfilt() - Gaussian filtering (adaptive sigma: 0.5-1.5)
        3. wiener2()     - Wiener filtering (window:  5x5 or 7x7)
        4. imnlmfilt()   - Non-local means filtering
        5. imsharpen()   - Unsharp masking for edge enhancement

metrics.m
---------
    Purpose: Calculate image quality metrics
    Inputs:  Reference image, Test image
    Outputs: MSE, PSNR (dB), SSIM

================================================================================
                            TROUBLESHOOTING
================================================================================

Problem:  "Undefined function 'imnlmfilt'"
Solution: You need Image Processing Toolbox.  Check with: ver('images')

Problem: "Cannot find file 'images/original_baboon.png'"
Solution: Make sure you are in the correct directory.  Run: cd 'path/to/project'

Problem: Images not displaying
Solution: Check if figures are minimized or run:  figure; to create new window

Problem: "Out of memory"
Solution: Close other applications or process images one at a time

Problem: Results folder not created
Solution: The script creates it automatically. If issues persist, manually create: 
          >> mkdir('results')

================================================================================
                              CONTACT
================================================================================

For questions or issues: 
    - Doğa Güneş:  20210602009@ogr.ikcu.edu.tr
    - Benhur Rahman Okur:  20220602059@ogr.ikcu.edu.tr

================================================================================
                          END OF README
================================================================================