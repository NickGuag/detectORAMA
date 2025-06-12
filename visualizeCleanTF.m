function visualizeCleanTF()
   % Load necessary data from base workspace
    T = evalin('base', 'T');
    FkeepBS = evalin('base', 'FkeepBS');
    meanBaseBS = evalin('base', 'meanBaseBS');
    stdBaseBS = evalin('base', 'stdBaseBS');
   
     % Initialize CleanTF/sumTrans if missing 
    if ~evalin('base', 'exist(''CleanTF'', ''var'')')
        assignin('base', 'CleanTF', zeros(size(T)));
    end
    if ~evalin('base', 'exist(''sumTrans'', ''var'')')
        assignin('base', 'sumTrans', zeros(1, size(T, 2)));
    end
   
    % if ~evalin('base', 'exist(''StN_Quality'', ''var'')')
    % assignin('base', 'StN_Quality', ones(1, size(T, 2)));
    % end

    % Initialize/reuse column parameters
    if evalin('base', 'exist(''columnParams'', ''var'')')
        columnParams = evalin('base', 'columnParams');
    else
        numColumns = size(T, 2);
        defaultParams = struct(...
            'ThreshFraction', getBaseVar('ThreshFraction', 0.05),...
            'skipRows', getBaseVar('skipRows', 10),...
            'stdBaseMulti', getBaseVar('stdBaseMulti', 3),...
            'stdMovingMulti', getBaseVar('stdMovingMulti', 1.5),...
            'rowWindow', getBaseVar('rowWindow', 20),...
            'peakWindow', getBaseVar('peakWindow', 8),...
            'stnQuality', getBaseVar('stnQuality', 1));
        
        columnParams = repmat(defaultParams, 1, numColumns);
        assignin('base', 'columnParams', columnParams);
    end

    % Create main figure
    fig = uifigure('Name', 'ROI Analysis', 'Position', [100 100 1400 900]);
    
    % Initialize parameters structure
    params = struct('currentCol', 1);

    % Create UI components
    ax = uiaxes(fig, 'Position', [350 100 1000 750]);
    
    % Add synchronized zooming for yyaxis
    z = zoom(fig);
    z.ActionPostCallback = @(~,~) synchronizeYAxes(ax);
    z.Enable = 'on';
  
    createMainParamsPanel(fig);
    createNavigationControls(fig);

    
    % % Create UI components
    % ax = uiaxes(fig, 'Position', [350 100 1000 750]);
    % createMainParamsPanel(fig);
    % createNavigationControls(fig);
    
    % Initialize with first column
    updateGUIControls();
    processAndPlot();

    %% Nested Functions
    function value = getBaseVar(varName, default)
        % Get variable from base workspace or use default
        if evalin('base', ['exist(''' varName ''', ''var'')'])
            value = evalin('base', varName);
        else
            value = default;
        end
    end

    function createMainParamsPanel(fig)
        panel = uipanel(fig, 'Title','Transient Parameters', 'Position',[20 550 300 330]);
        %quality
        uilabel(panel, 'Text','StN Quality:', 'Position',[10 250 100 22]);
    
        params.stnQualityEdit = uieditfield(panel, 'numeric',...
        'Value', columnParams(1).stnQuality,...
        'Position',[120 250 60 22],...
        'ValueChangedFcn',@(src,~)paramChanged('stnQuality', src.Value));
        
       % peakWindow
        uilabel(panel, 'Text','Peak Window:', 'Position',[10 220 100 22]);
        params.ThreshFractionEdit = uieditfield(panel, 'numeric',...
            'Value', columnParams(1).peakWindow,...
            'Position',[120 220 60 22],...
            'ValueChangedFcn',@(src,~)paramChanged('peakWindow', src.Value));
        
        
        % ThreshFraction
        uilabel(panel, 'Text','Threshold Fraction:', 'Position',[10 190 100 22]);
        params.ThreshFractionEdit = uieditfield(panel, 'numeric',...
            'Value', columnParams(1).ThreshFraction,...
            'Position',[120 190 60 22],...
            'ValueChangedFcn',@(src,~)paramChanged('ThreshFraction', src.Value));
        
        % SkipRows
        uilabel(panel, 'Text','Period Window:', 'Position',[10 160 100 22]);
        params.skipRowsEdit = uieditfield(panel, 'numeric',...
            'Value', columnParams(1).skipRows,...
            'Position',[120 160 60 22],...
            'ValueChangedFcn',@(src,~)paramChanged('skipRows', src.Value));
        
        % StdBaseMulti
        uilabel(panel, 'Text','Baseline Correct:', 'Position',[10 130 100 22]);
        params.stdBaseMultiEdit = uieditfield(panel, 'numeric',...
            'Value', columnParams(1).stdBaseMulti,...
            'Position',[120 130 60 22],...
            'ValueChangedFcn',@(src,~)paramChanged('stdBaseMulti', src.Value));
        
        % RowWindow
        uilabel(panel, 'Text','Noise Window:', 'Position',[10 100 100 22]);
        params.rowWindowEdit = uieditfield(panel, 'numeric',...
            'Value', columnParams(1).rowWindow,...
            'Position',[120 100 60 22],...
            'ValueChangedFcn',@(src,~)paramChanged('rowWindow', src.Value));
        
        % StdMovingMulti
        uilabel(panel, 'Text','Noise Sensitivity:', 'Position',[10 70 100 22]);
        params.stdMovingMultiEdit = uieditfield(panel, 'numeric',...
            'Value', columnParams(1).stdMovingMulti,...
            'Position',[120 70 60 22],...
            'ValueChangedFcn',@(src,~)paramChanged('stdMovingMulti', src.Value));
       
        % Save state button
        uibutton(panel, 'Text','Save Params', 'Position',[10 30 100 30],...
            'ButtonPushedFcn',@saveState);
      
    end
    function createNavigationControls(fig)
        % Column navigation controls
        uilabel(fig, 'Text','Cell Number:', 'Position',[400 870 100 22]);
        params.colNumEdit = uieditfield(fig, 'numeric',...
            'Position',[500 870 60 22],...
            'Value', params.currentCol,...
            'Limits',[1 size(T,2)],...
            'ValueChangedFcn',@(src,~)navigateToColumn(src.Value));
        
        uibutton(fig, 'Text','Previous', 'Position',[400 20 80 30],...
            'ButtonPushedFcn',@(~,~)navigateToColumn(-1)); % Pass delta -1
        
        uibutton(fig, 'Text','Next', 'Position',[500 20 80 30],...
            'ButtonPushedFcn',@(~,~)navigateToColumn(1)); % Pass delta +1
        
        
    end

    function navigateToColumn(input)
        % Handle both absolute and delta inputs
        if isscalar(input) && (input == -1 || input == 1)
            % Delta navigation from buttons
            newCol = params.currentCol + input;
        else
            % Absolute navigation from edit field
            newCol = input;
        end
        
        % Validate and update current column
        newCol = max(1, min(newCol, size(T,2)));
        params.currentCol = newCol;
        params.colNumEdit.Value = newCol;
        updateGUIControls();
        processAndPlot();
    end

    function updateGUIControls()
        % Update UI with current column's parameters
        col = params.currentCol;
        params.ThreshFractionEdit.Value = columnParams(col).ThreshFraction;
        params.skipRowsEdit.Value = columnParams(col).skipRows;
        params.stdBaseMultiEdit.Value = columnParams(col).stdBaseMulti;
        params.stdMovingMultiEdit.Value = columnParams(col).stdMovingMulti;
        params.rowWindowEdit.Value = columnParams(col).rowWindow;
        params.peakWindowEdit.Value = columnParams(col).peakWindow; 
        params.stnQualityEdit.Value = columnParams(col).stnQuality; 
        
    end

    function paramChanged(paramName, value)
        % Update parameter for current column
        columnParams(params.currentCol).(paramName) = value;
        assignin('base', 'columnParams', columnParams);
        processAndPlot();
    end

    function processAndPlot()
    % Process with current column's parameters
    col = params.currentCol;
    
    cp = columnParams(col);
    
    [~, new_CleanTF_col, ~, ~, new_sumTrans] = TFcleaner(...
        T(:, col),...
        cp.ThreshFraction,...
        FkeepBS(:, col),...
        cp.skipRows,...
        meanBaseBS(:, col),...
        stdBaseBS(:, col),...
        cp.stdBaseMulti,...
        cp.stdMovingMulti,...
        cp.rowWindow, ...    
        cp.peakWindow, ...
        cp.stnQuality);
    
    % Update CleanTF and sumTrans in base workspace
    if evalin('base', 'exist(''CleanTF'', ''var'')')
        CleanTF = evalin('base', 'CleanTF'); % Load existing
    else
        CleanTF = zeros(size(T)); % Initialize if missing
    end
    CleanTF(:, col) = new_CleanTF_col; % Update current column
    assignin('base', 'CleanTF', CleanTF); % Save back
    
    if evalin('base', 'exist(''sumTrans'', ''var'')')
        sumTrans = evalin('base', 'sumTrans'); % Load existing
    else
        sumTrans = zeros(1, size(T, 2)); % Initialize if missing
    end
    sumTrans(col) = new_sumTrans; % Update current column
    assignin('base', 'sumTrans', sumTrans); % Save back

    % Update StN_Quality in base workspace
    % if evalin('base', 'exist(''StN_Quality'', ''var'')')
    %     StN_Quality = evalin('base', 'StN_Quality');
    % else
    %     StN_Quality = ones(0, size(T, 2)); % Initialize with default 1s
    % end
    % StN_Quality(col) = columnParams(col).stnQuality;
    % assignin('base', 'StN_Quality', StN_Quality);

    
    %Update visualization
    cla(ax);
   %yyaxis(ax, 'left');
    yyaxis(ax, 'left'); % Force left axis creation

    plot(ax, FkeepBS(:, col), 'Color', [0.7 0 0], 'LineWidth', 1);
    ylabel('FkeepBSneu');

    % yyaxis(ax, 'right');
    yyaxis(ax, 'right'); % Force right axis creation
    stem(ax, find(new_CleanTF_col), ones(nnz(new_CleanTF_col), 1),...
        'filled', 'Color', [0 0.4 0.7], 'MarkerSize', 4);
    ylabel('CleanTF Peaks');

    title(ax, sprintf('Cell %d Analysis - %d transients detected', col, new_sumTrans));
end


    function saveState(~,~)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        backupName = ['TF_columnParams_' timestamp];
        
        savedState = columnParams;
           
        
        assignin('base', backupName, savedState);
        msgbox(sprintf('State saved as %s', backupName), 'Success');
    end

function synchronizeYAxes(ax)
    % Check if both y-axes exist
    if numel(ax.YAxis) < 2
        return; % Exit if only one axis exists
    end
    
    % Initialize UserData if missing
    if ~isfield(ax.UserData, 'axesScale') || isempty(ax.UserData.axesScale)
        try
            leftLimits = ax.YAxis(1).Limits;
            rightLimits = ax.YAxis(2).Limits;
            ax.UserData.axesScale = diff(rightLimits) / diff(leftLimits);
            ax.UserData.axesOffset = rightLimits(1) - ax.UserData.axesScale * leftLimits(1);
        catch
            return; % Exit if axes aren't ready
        end
    end

    % Get current active axis
    try
        activeYAxis = find([ax.YAxis(1).Color; ax.YAxis(2).Color] == ax.YColor);
    catch
        return; % Fail-safe exit
    end

    % Update limits
    if activeYAxis == 1
        newRight = ax.YAxis(1).Limits * ax.UserData.axesScale + ax.UserData.axesOffset;
        ax.YAxis(2).Limits = newRight;
    else
        newLeft = (ax.YAxis(2).Limits - ax.UserData.axesOffset) / ax.UserData.axesScale;
        ax.YAxis(1).Limits = newLeft;
    end
end

end



