% Files needed:
%  - Registered .tif stack
%  - Fall.mat
%  - iscell.npy

%% Input files
% tiff_file = fullfile('Data', 'Data1403BSub_registered.tif');
% %tiff_file = 'Data1404_180301_1.tif';
% mat_file = fullfile('Data', 'Data1403_154137_op94.mat');

%% Create registered image matrix

% Load registered .tif stack
info = imfinfo(tiff_file);
num_slices = numel(info);

% Preallocate a 3D single-precision matrix
M = single(zeros(info(1).Height, info(1).Width, num_slices));

% Read each slice into the matrix
for i = 1:num_slices
    M(:,:,i) = single(imread(tiff_file, i));
end

%% Format ROIs for Suedo input

% Get size of image matrix
[ydim, xdim, num_slices] = size(M);
% Average pixel values over time
tif_mean = double(mean(M, 3));
% Load suite2p MATLAB output
mat_data =  load(mat_file);
stat = mat_data.stat;
% Load iscell martrix
iscell = mat_data.iscell;
iscell = iscell(:,1);
% Filter out ROIs that are not cells
stat_cell = stat(iscell == 1);
spks = (mat_data.spks);
F = (mat_data.F);
Fneu = mat_data.Fneu;
% Cols=ROIs that are cells, rows=fluorescent intensity/frame  
T = (spks(iscell == 1, :))';
Fneu = (Fneu(iscell == 1, :))';

Fkeep = (F(iscell == 1, :))';
FkeepNeu = Fkeep - Fneu;
% Create variable where non-zero elements = 1
TF = T;
TF(TF ~= 0) = 1;
% Create ROI matrices
P = zeros(ydim, xdim, length(stat_cell));
for i=1:length(stat_cell)
    roi=stat_cell(i);
    roi = roi{1};
    ypix = double(roi.ypix) + 1;
    xpix = double(roi.xpix) + 1;
    roi_img = zeros(size(tif_mean));
    roi_img(sub2ind(size(roi_img), ypix, xpix)) = 1;
    roi_img = roi_img .* tif_mean;
    %figure; imshow(mat2gray(roi_img));
    P(:,:,i) = roi_img;
end
