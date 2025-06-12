
%Find how many ROIs
    [rownum, colnum] = size(se.tcDefault.transientInfo);

   
% Make any ROI excluded by standard deviation an artifact in the transient
% classification 
    for c = 1:rownum
        if excludeStd(c,1) == 1
          se.tcDefault.transientInfo(c).isArtifact = 1;
        end
% Make any ROI with quality score  of 1 an artifact in the transient
% classification 
        if columnParams(c).stnQuality == 1
          se.tcDefault.transientInfo(c).isArtifact = 1;
        end
    end



   