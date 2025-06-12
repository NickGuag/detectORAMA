
%Find how many ROIs
    [rownum, colnum] = size(se.tcDefault.transientInfo);

%make matrix for events
    detectoramaOUT.events = cell(rownum, 1);

%get time course
    detectoramaOUT.traces = se.tcDefault.tc;

%get framerate and si (Hz, 1/framerate), generate column
    detectoramaOUT.framerate = mat_data.ops.fs;
    detectoramaOUT.si = 1 / detectoramaOUT.framerate;
    
% generate column with # of frames rows, containing time of eacy frame in seconds
    detectoramaOUT.timeC = ((1:num_slices)' * detectoramaOUT.si);
    detectoramaOUT.ROIparams = columnParams;
%set Noise cutoff
    cutoff = .5;
    
    
%populate detectoramaOUT.events{c}
    for c = 1:rownum
        
        if se.tcDefault.transientInfo(c).isArtifact == 0;
        %Column 1
        %the peak transient frame = First frame + the pre transiet pad time, multiply by si to get time of transient 
            tPre = se.tcDefault.transientInfo(c).params.tPre;
            times = se.tcDefault.transientInfo(c).times;
            timePeaks = (times(:,1) + tPre) * detectoramaOUT.si;

        %Column 2
        %Classification of transient, 1 = true, -1 = false
            timePeaks(:,2) = se.tcDefault.transientInfo(c).classification;
            

        %Column 3
        %may be useful to quickly elimnate high hoise transients outside of the GUI
            % timePeaks(:,3) = se.tcDefault.transientInfo(c).autoClass.resRatios;
            
       
          
            
          
          %Remove non-1 transients
            TransientsKeep = timePeaks(timePeaks(:,2) == 1,:);

        %Noise filter, if necessary
            %TransientsKeep = TransientsKeep(TransientsKeep(:,3) < cutoff,:);

        %add to events out
            [rows, cols] = size(TransientsKeep);
            detectoramaOUT.events{c} = TransientsKeep;
        end
    end

%save as variables recognized by ImageAnalysisHub
   


    

%save ORAMA file
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    directory = 'C:\Users\nag4g\Documents\MATLAB\ORAMA'; %replace with Directory locations
    filenameORAMA = [ShortTitle '_Orama_' timestamp '.mat'];
    fullPathORAMA = fullfile(directory, filenameORAMA);

    save(fullPathORAMA, 'detectoramaOUT', '-v7.3');


    filenameORAMA_IAH = [ShortTitle '_Orama.mat'];
    mkdir (directory, ShortTitle);
    pathORAMA = [directory '\' ShortTitle ];
    fullPathORAMA_IAH = fullfile(pathORAMA, filenameORAMA_IAH);
     save(fullPathORAMA_IAH, 'detectoramaOUT', '-v7.3');
