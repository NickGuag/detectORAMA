function [TransientPeaks, CleanTF, ThrFracVals, UsedParams, sumTrans, stnQuality] = TFcleaner(T, ThreshFraction, FkeepBS, skipRows, meanBaseBS, stdBaseBS, stdBaseMulti, stdMovingMulti, rowWindow, peakWindow, stnQuality)
    % Input parameters and output variables documentation
    % [Same as previous implementation]

    %% Initialize parameter tracking
    [rownum, colnum] = size(T);
    UsedParams = struct();
    UsedParams.FirstPass = struct(...
        'ThreshFraction', ThreshFraction,...
        'skipRows', skipRows,...
        'stdBaseMulti', stdBaseMulti,...
        'stdMovingMulti', stdMovingMulti,...
        'rowWindow', rowWindow,...
        'peakWindow', peakWindow,...
        'stnQuality', stnQuality);
    
    %% First pass processing
    [Tcut, ~] = BaseCutOff(T, FkeepBS, meanBaseBS, stdBaseBS, stdBaseMulti);
    %%
    % Handle ThreshFraction input
    if nargin < 2 || isempty(ThreshFraction)
        ThreshFraction = 0.001;
    end
    if isscalar(ThreshFraction)
        ThrFracVals = repmat(ThreshFraction, 1, colnum);
    else
        ThrFracVals = ThreshFraction;
    end
    ThrFracVals(ThrFracVals < 0.001) = 0.001;
%%
    % Process all columns
   
 
    
 


[rows, cols] = size(Tcut);
TransientPeaks = zeros(size(Tcut));
CleanTF = zeros(size(Tcut));

for c = 1:cols
    % Create working copy for this column
    remaining_col = Tcut(:, c);
    
    while any(remaining_col > 0)
        % Find all non-zero indices
        non_zero_idx = find(remaining_col > 0);
        if isempty(non_zero_idx)
            break; 
        end
        
        % Find minimum value and its row in Tcut
        [~, min_pos] = min(remaining_col(non_zero_idx));
        rTcut = non_zero_idx(min_pos);
        
        % Find corresponding max position in FkeepBS window
        start_idx = max(1, rTcut-1);
        end_idx = min(rows, rTcut + peakWindow);
        [~, max_pos] = max(FkeepBS(start_idx:end_idx, c));
        r2 = start_idx + max_pos-1;
        
        % Update FindCleanTF with value from Tcut at r2 position
        TransientPeaks(r2, c) = Tcut(rTcut, c);
        
        % Mark this position as processed
        remaining_col(rTcut) = 0;
    end
end
for c = 1:cols
        %% Initial peak detection
        Tcol = TransientPeaks(:, c);
        ThreshMax = max(Tcol) * ThrFracVals(c);
        Tcol(Tcol < ThreshMax) = 0;

        while any(Tcol > 0)
            
            
            [~, maxIdx] = max(Tcol);
            %FindCleanTF(maxIdx,c) = 1;
            CleanTF(maxIdx,c) = 1;
            %% shift transient using FkeepBSneu
%             startIdx = max(1,maxIdx-2);
%             endIdx = min(rownum,maxIdx+peakWindow);
%             [~, relIdx] = max(FkeepBS(startIdx:endIdx,c));
%             CleanTF(startIdx+relIdx-1,c) = 1;

            %% Apply exclusion zone
            Tcol(max(maxIdx-skipRows,1):min(maxIdx+skipRows,rownum)) = 0;
        end

        % Final cleanup with moving baseline
        CleanTF(:,c) = MovingBaseCutOff(CleanTF(:,c), FkeepBS(:,c),...
                                      stdBaseBS(1,c), stdMovingMulti, rowWindow);
end

sumTrans = zeros(1, cols);
for c= 1:cols
        sumTrans(1,c)= sum(CleanTF(:,c));
 end
end

        
        
%         
%         %% Initial peak detection
%         Tcol = Tcut(:, c);
%         ThreshMax = max(Tcol) * ThrFracVals(c);
%         Tcol(Tcol < ThreshMax) = 0;
% 
%         while any(Tcol > 0)
%             
%             
%             [~, minIdx] = min(Tcol);
%             startIdx = max(1,minIdx-1);
%             endIdx = min(rownum,minIdx+peakWindow);
%              [~, relIdx] = max(FkeepBS(startIdx:endIdx,c));
%            FindCleanTF(startIdx+relIdx-1,c) = Tcut(minIdx,c);
%         end
% 
%             %% shift transient using FkeepBSneu
%              [~, maxIdx] = max(FindCleanTF);
%             while  any(FindCleanTF > 0)
%                 startIdx = max(1,minIdx-1);
%                 endIdx = min(rownum,minIdx+peakWindow);
%                 [~, relIdx] = max(FkeepBS(startIdx:endIdx,c));
%                 CleanTF(startIdx+relIdx-1,c) = 1;
%             
%             %% Apply exclusion zone
%             FindCleanTF(max(minIdx-6,1):min(minIdx+skipRows-1,rownum)) = 0;
%             
%             end
%         end
% 
%         % Final cleanup with moving baseline
%         CleanTF(:,c) = MovingBaseCutOff(CleanTF(:,c), FkeepBS(:,c),...
%                                       stdBaseBS(1,c), stdMovingMulti, rowWindow);
% 
%     
% end  
%     
    %% Helper Functions

function [Tcut, stdBaseMulti] = BaseCutOff(T, FkeepBS, meanBaseBS, stdBaseBS, stdBaseMulti)

% Remove transients below meanBaseBS + (stdBaseBS * stdBaseMulti)
    Tcut = T;
    threshFkeepBS = (stdBaseBS * stdBaseMulti) + meanBaseBS;
    mask = FkeepBS < threshFkeepBS;
    Tcut(mask) = 0;
end



function CleanTF = MovingBaseCutOff(CleanTF, FkeepBS, stdBase, stdMovingMulti, rowWindow)
    newCol = zeros(size(CleanTF));
    
    for r = 1:length(CleanTF)
        if CleanTF(r) == 1
            %% Calculate local minima
            befStart = max(1, r-rowWindow);
            aftEnd = min(length(CleanTF), r+rowWindow);
            
            befVals = FkeepBS(befStart:r-1);
            aftVals = FkeepBS(r+1:aftEnd);
            meanbef = mean(befVals);
            meanaft = mean(aftVals);
            meanbefaft = ((meanbef + meanaft) / 2) + (stdBase); % stdBase*2?
            befMin = mean(mink(befVals,2));
            aftMin = mean(mink(aftVals,2));
            %minVal = min(befMin, aftMin);
            %minVal = max(befMin, aftMin);
            minVal = (befMin*2 + aftMin) /3;
           % befMax = mean(maxk(befVals,5));
            %aftMax = mean(maxk(aftVals,5));
            %maxVal = max(befMax, aftMax);
            
            %% Apply final cutoff
            if (FkeepBS(r) - minVal) > stdBase*stdMovingMulti %%&& FkeepBS(r) > meanbefaft
                newCol(r) = 1;
            end
        end
    end
    CleanTF = newCol;
end
