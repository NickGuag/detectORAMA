
%% Run each section sequentially. Do not run the whole script at once. 


%% 1. Load files from suite2p into Seudo 

    % Load with relevent movie (*.tif) and suite2p (.mat) filenames, from folder 'Data')
    
        tiff_file = fullfile('Data', 'Data1438mcBSub1.tif');
        mat_file = fullfile('Data', 'Data1438mcBSub1.mat');
        ShortTitle = 'Data1438';
        
        
        %load data into matlab for use with suedo
         suite2p_to_seudo;
         % F = fluorescence trace
         % FKeep = fluorescence trace of kept ROIs
         % Fneu = neuropil fluorescence trace for kept ROIs
         % FkeepNeu =  FKeep - FkeepNeu
 %% 2. Generate timecourse for analysis      
        
    %generate baseline timecourse where min value = 0 (FkeepBS), or neurpil subtractred timecourse (FkeepNeu * multiplier). 
        % Last number is the Fneu multiplier. 
       
        [FkeepBS, FkeepBSneu, FkeepNeu]=FkeepBScalcNeu(Fkeep, Fneu, .9);
        
    %Run if you want to use FkeepNeu/FkeepBSneu instead of FkeepBS. Overwrites FkeepBS.
    % I have been using FkeepBS = FkeepNeu exclusively.
            
        FkeepBS = FkeepNeu; 
        % FkeepBS = FkeepBSneu;
       
    %Find baseline mean and std dev from FkeepBS, within window of windowSize rows (second input value in function).
         % excludes cells from analysis (does not remove them) if min std * excSTD is < max std
         % (eliminated in isArtifact after classifyTransients)
         
        excSTD = 3;
        [meanBaseBS,stdBaseBS,excludeStd] = BaselineStdFkeep(FkeepBS,110,excSTD);
  
      

%% 3. Set default variables for detection of transients using Gui (in next section): 

    % Parameter descriptions
    % 
    % peakWindow 
    %     % finds peak of the transient signal within a rows -1 to peakWindow, and moves the transient marker to that time point.
    %     % Suggested range 5-8  higher gets more transients... sometimes. 5 works 99% of the time
    % 
    % % ThreshFraction
    %     % the fraction of peak intensity of deconvoluted fluoresenct
    %     signal ; smaller transients  (marked by T from sutie2p) will be
    %     eliminated. e.g., .1 will elimnate all transiets that have peak fl intensity less
    %     than 10% of the max transient fl. intensity.
    %     % Suggested range: .01-.2; good intervals to try are .01, .05, .1, .12, .15, .2
    %     % Higher values = fewer events
    % 
    % % skipRows 
    %     % For each event, starting with the highest amplitude, the amount
    %     of time in 0.1 second intervals trailing the transient in which
    %     no other event can occur. Directly related to event frequency
    %     within a burst. Higher frequency, lower skipRows
    %     % Suggested range: 6-16; increase for fewer false postivives, decrease for too few events detected due to high event frequency. 
    % 
    % 
    % % stdBaseMulti (Baseline SD*X) 
    %     % a multiplier of the standard deviation dervied from baseline activity. any transient with peak fl. intensity less than StdBaseMulti * stdBaseBS (derived from BaselineStdFkeep function) will be eliminated
    %     % Suggested range: 4-10 higher = fewer events near baseline
    % 
    % 
    % stdMovingMulti and rowWindow are used to remove tiny spikes riding on big spikes. 
    %
    % %rowWindow (Window Size)
    %     % number of rows evaluated before and after (e.g. a value of 6 means 6 rows before, 6 rows after) to determine if the transient meets the threshhold to keep. 
    %     % Suggested range= 6-25, suggested intervals 8 10 15 20 25); Higher = more transients. 
    % 
    % % stdMovingMulti% (Window STD *X)
    %   % a multiplier of the standard deviation from moving "baseline" defined from rowWindow, otherwise same as stdBaseMulti
    %   % Suggested range 3-6; decrease/increase will detect more/fewer events, respectively. designed to eliminate little peaks riding big peaks
    
        peakWindow =5;  
        ThreshFraction = .01; 
        skipRows = 6; 
        stdBaseMulti =10; 
        rowWindow = 7; 
        stdMovingMulti = 5; 
        stnQuality = 0;
    
    % Put parameters together for CleanTF to read. Will overwrite any saved column parameters, so be sure to save in the GUI if you want to keep for certain cells. 
    % If you start and realize your defaults are off, change params above section and run UpdateCleanParameters.
    
        [columnParams] = UpdateCleanParams(T, ThreshFraction, skipRows, stdBaseMulti, stdMovingMulti, rowWindow, peakWindow, stnQuality);      
    
    % Retro quality scores for all columns
    %  columnParams = evalin('base', 'columnParams');
    % stnQualityScores = [columnParams.stnQuality];
    %[columnParams(1:40).stnQuality] = deal(0);

       
%% 4. Detect transients in GUI
   
        [TransientPeaks, CleanTF, ThrFracVals, UsedParams, sumTrans, stnQuality] = TFcleaner(T, ThreshFraction, FkeepBS, skipRows, meanBaseBS, stdBaseBS, stdBaseMulti, stdMovingMulti, rowWindow, peakWindow, stnQuality) ;               
        
        visualizeCleanTF(); 
            
         %columnParams = TF_columnParams_20250419_172022;
                            
%% 5. Create seudo object
        %se = seudo(M,P)                    %analysis on raw signal
        se = seudo(M,P,'timeCourses',FkeepBS) ;  %analysis on suite2p timecourse

    %make file size more managable:
        clear M
        clear P
%%  6. Identify transients
    
    
    % use CleanTF to compute transients
         se.computeTransientInfo('default','transientFrames', CleanTF, 'tPre', 5 , 'tPost', 13)
        
    
    % Auto Clasify Transients  (set to detect all). May need to adjust
    % corrThreshold slightly on an ROI to ROI bases, but .2 is usually
    % pretty good. 

        corrThresh = .2;

        se.autoClassifyTransients('default','overwrite',true, 'corrThresh',0.2)
        
    % Remove crappy ROIs that fail the std deve test (excludeStd) or are
    % marked as having a quality of 1 in the visualizeCleanTF GUI. 
        
        isArtifact;

    % View in classifyTransients GUI, manually correct if needed. 

        se.classifyTransients

       
%% 7. Save     
        
% in format for Christina's ORAMA analysis script: ImageAnalysisHub.mlapp    
        SaveORAMA

% matlab variables of transient analysis
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        directory = 'C:\Users\nag4g\Documents\MATLAB\Suedo\Nick'; %replace with Directory locations
        filename = "se_" + ShortTitle + "_" + timestamp + ".mat";
        fullPath = fullfile(directory, filename);
        save(fullPath, '-v7.3');
        
 % save ORAMAs grouped by quality, inputed in visualizeCleanTF()       
        QualityControl;
        
        
        clear all;

