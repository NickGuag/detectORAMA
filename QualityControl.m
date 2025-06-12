
Quality = 3;
[rownum, colnum] = size(detectoramaOUT.events);
eventOrig = detectoramaOUT.events;

for quality = 3:5

KeepEvents = cell(size(detectoramaOUT.events));
for r = 1:rownum

if detectoramaOUT.ROIparams(r).stnQuality >= Quality && isempty(detectoramaOUT.events(r)) == 0;
    KeepEvents(r) = detectoramaOUT.events(r);

end 
end
detectoramaOUT.events = KeepEvents;


%save ORAMA file
    
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    QualityName = num2str(Quality);
    directoryQuality = ['C:\Users\nag4g\Documents\MATLAB\ORAMA\' QualityName]; %replace with Directory locations
    filenameORAMA = [ShortTitle '_Q' QualityName  '_Orama_' timestamp '.mat'];
    fullPathORAMA = fullfile(directoryQuality, filenameORAMA);
    save(fullPathORAMA, 'detectoramaOUT', '-v7.3');

    QualityName = num2str(Quality);
    shortTitleORAMA = [ShortTitle '_Q' QualityName];
    filenameORAMA_IAH = [ShortTitle '_Q' QualityName  '_Orama.mat'];

    pathORAMA = [directoryQuality '\' shortTitleORAMA ]
    fullPathORAMA_IAH = fullfile(pathORAMA, filenameORAMA_IAH);
    mkdir (directoryQuality, shortTitleORAMA);
    
    
     save(fullPathORAMA_IAH, 'detectoramaOUT', '-v7.3');
    
    detectoramaOUT.events = eventOrig;
    Quality = Quality +1;
end
    