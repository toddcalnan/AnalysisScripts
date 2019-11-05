function [distraction] = determineDistraction(ROIwrong, gazeEventColumn, gazeOnMediaColumn, countThreshold, ROIthreshold)

m=1; %initializing for while loop
count = 0; %initializing
distraction = 0; %initializing
ROIcount = 0; %initializing
while m<size(ROIwrong,1) && count < countThreshold && ROIcount < ROIthreshold
    if ROIwrong(m) == 1 && strcmp(gazeEventColumn(m), 'Fixation')
        ROIcount = ROIcount+1; 
    end
    if (~isnan(gazeOnMediaColumn(m,1)) || ~isnan(gazeOnMediaColumn(m,2))) && strcmp(gazeEventColumn(m), 'Fixation')
        count = count+1;
    end
    m = m+1;
end

if count >= countThreshold || ROIcount >=ROIthreshold
    distraction = 1;
end