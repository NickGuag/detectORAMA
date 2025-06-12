function [FkeepBS, FkeepBSneu, FkeepNeu, FkeepNeuRel] = FkeepBScalc(Fkeep, Fneu, neuFactor)
 [rows, cols] = size(Fkeep);

%     % Baseline adjustment
%     
    minFkeep = min(Fkeep, [], 1);
    FkeepBS = Fkeep - minFkeep;
%  
    subFneu= Fneu * neuFactor;
    FkeepNeu = Fkeep - subFneu ;
     
    FkeepNeuRel = Fkeep ./ Fneu ;
    
    % Vectorized baseline adjustment (no loop needed)
    minFkeepNeu = min(FkeepNeu, [], 1);
    FkeepBSneu = FkeepNeu - minFkeepNeu;
    

end
