function [columnParams] = UpdateCleanParams(T, ThreshFraction, skipRows, stdBaseMulti, stdMovingMulti, rowWindow, peakWindow, stnQuality)
%UNTITLED2 Summary of this function goes here

  [rownum, colnum] = size(T);
    UsedParams = struct();
    UsedParams.FirstPass = struct(...
        'ThreshFraction', ThreshFraction,...
        'skipRows', skipRows,...
        'stdBaseMulti', stdBaseMulti,...
        'stdMovingMulti', stdMovingMulti,...
        'rowWindow', rowWindow,...
        'peakWindow', peakWindow, ...
        'stnQuality', stnQuality);

for i = 1:colnum
    columnParams(i).ThreshFraction = ThreshFraction;
    columnParams(i).skipRows = skipRows;
    columnParams(i).stdMovingMulti = stdMovingMulti;
    columnParams(i).rowWindow = rowWindow;
    columnParams(i).peakWindow = peakWindow;
    columnParams(i).stdBaseMulti = stdBaseMulti;
    columnParams(i).stnQuality = stnQuality;
end

%   Detailed explanation goes here

end

