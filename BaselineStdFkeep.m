function [meanBaseBS,stdBaseBS, excludeStd] = BaselineStdFkeep(FkeepBS,windSize, excSTD)
%% Inputs
    % FKeepBS = processed trace

    % windSize = number of consecutive frames for finding baseline mean and
    %   Std

    % excSTD = the exclusion factor multiplied by the minSTD to determine
    %   exclution



     [rows, cols] = size(FkeepBS);
    meanBaseBS = zeros(1, cols);
    stdBaseBS = zeros(1, cols);
    threshFkeepBS = zeros(1, cols);
    excludeStd = zeros(cols,2);
    for col = 1:cols
        columnData = FkeepBS(:, col);
        minMean = inf;
        minStd = inf; 
        maxStd = 0;
        bestStart = 1;
        
        % Find optimal window
        for startRow = 1:(rows - windSize + 1)
            endRow = startRow + windSize - 1;
            currentWindow = columnData(startRow:endRow);
            currentMean = mean(currentWindow);
            currentStd = std(currentWindow);
            
            % if currentMean < minMean
            %     minMean = currentMean;
            %     bestStart = startRow;
            % end

                if currentStd < minStd
                    minStd = currentStd;
                    bestStart = startRow;
                end

                if currentStd > maxStd
                   maxStd = currentStd;                
                end
             
          end
        %Exclude ROI if the Signal to noise is <3 std dev
        if maxStd < excSTD*minStd
            excludeStd(col,1) = 1;
        end
        excludeStd(col,2) = maxStd / minStd;
        % Calculate statistics
        bestWindow = columnData(bestStart:bestStart+windSize-1);
        
        meanBaseBS(1,col) = mean(bestWindow); % Column-specific assignment
        if meanBaseBS(1, col) < 0
            meanBaseBS(1, col) = 0;
        end
        stdBaseBS(1,col) = std(bestWindow,1);      % Column-specific assignment
        threshFkeepBS(1,col) = stdBaseBS(1,col)*3 + meanBaseBS(1,col); % Column-specific

end

