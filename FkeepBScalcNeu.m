function [FkeepBS, FkeepBSneu, FkeepNeu] = FkeepBScalc(Fkeep, Fneu, neuFactor)
 [rows, cols] = size(Fkeep);

%% Inputs
    % FKeep = the origninal trace from only the ROIs that are cells (iscell= true)

    % Fneu = the neuropil trace values for each ROI

    % neuFactor = the Fneu multiplier used for calculating FkeepBSneu

%% FkeepBS:  Calculating zeroed baseline FKeep
    
    % Baseline adjustment FKeep, finds the smallest value and subtracts from every other value for each ROI
    %     output
    %     
        minFkeep = min(Fkeep, [], 1);
        FkeepBS = Fkeep - minFkeep;
    
%% FKeepNeu = raw signal (i.e., Fkeep) - (neuropil (i.e., Fneu) * multiplier (i.e. neuFactor) )
    %  subtract the Fneu from baseline Fkeep to generate FkeepNeu
        subFneu = Fneu * neuFactor;
        FkeepNeu = Fkeep - subFneu;
  
%% FkeepBSneu  =   FkeepNeu with zeroed baseline        
     %FkeepNeu(FkeepNeu < 0) = 0;

    minFkeepNeu = min(FkeepNeu, [], 1);
    FkeepBSneu = FkeepNeu - minFkeepNeu;

    
%     
end
