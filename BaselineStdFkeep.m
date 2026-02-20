function [meanBaseBS,stdBaseBS, excludeStd] = BaselineStdFkeep(FkeepBS,windSize, excSTD)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here



     [rows, cols] = size(FkeepBS);
    meanBaseBS = zeros(1, cols);
    stdBaseBS = zeros(1, cols);
    threshFkeepBS = zeros(1, cols);
    excludeStd = zeros(cols,2);
    maxWindSize = windSize*2;
    for col = 1:cols
        columnData = FkeepBS(:, col);
        columnMax = max(columnData);
        minMean = inf;
        minStd = inf; 
        maxStd = 0;
        minStart = 1;

        
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
                    minStart = startRow;
                    bestMinWindow = columnData(minStart:minStart+windSize-1);
                   meanMinWindow = mean(bestMinWindow);
                end

          end
   
                
        % Find optimal window
        for startRowMax = 1:(rows - maxWindSize + 1)
            endRow = startRowMax + maxWindSize - 1;
            currentWindow = columnData(startRowMax:endRow);
            currentMean = mean(currentWindow);
            currentStd = std(currentWindow);
            
            % if currentMean < minMean
            %     minMean = currentMean;
            %     bestStart = startRow;
            % end

               
                if currentStd > maxStd
                   maxStd = currentStd;  
                   maxStart = startRowMax;
                   bestMaxWindow = columnData(maxStart:maxStart+windSize-1);
                   meanMaxWindow = mean(bestMaxWindow);
                end
             
        end
        meanMinWindowS= log10(meanMinWindow);
        columnMaxS= log10(columnMax);
        minStdS = std(log10(columnData(minStart:minStart+windSize-1)));
        
          if columnMaxS < (excSTD*minStdS) + meanMinWindowS;
            excludeStd(col,1) = 1;
        end


        % if columnMax < (excSTD*minStd) + meanMinWindow;
        %     excludeStd(col,1) = 1;
        % end
        excludeStd(col,2) = minStd;
        excludeStd(col,3) = minStdS;
        excludeStd(col,4) = columnMax;
         excludeStd(col,5) = columnMaxS;
         excludeStd(col,6) = meanMinWindow;
         excludeStd(col,7) = meanMinWindowS;
         excludeStd(col,8) = minStart;
         %excludeStd(col,3) = maxStd;
         %excludeStd(col,6) = maxStart;
         %excludeStd(col,9) = meanMaxWindow;
        
        % Calculate statistics
        bestWindow = columnData(minStart:minStart+windSize-1);
        
        meanBaseBS(1,col) = mean(bestWindow); % Column-specific assignment
        if meanBaseBS(1, col) < 0
            meanBaseBS(1, col) = 0;
        end
        stdBaseBS(1,col) = std(bestWindow,1);      % Column-specific assignment
        threshFkeepBS(1,col) = stdBaseBS(1,col)*excSTD + meanBaseBS(1,col); % Column-specific

        
end

