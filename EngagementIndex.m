close all
clear
thePath = 'C:\Users\tmc54\Documents\EyeTracking\DukeACT_EGT\T1Background';
cd(thePath)
mainFolder = dir;
listOfSubjectFolders = {mainFolder(3:end).name}; %3:end means that it will start with the first subject and end with the last
sampleRate = 120; 
toleranceThreshold = 24; % how many samples we allow before calling something a distraction
setting = 'all'; % 'social', 'nonSocial', 'all' are the options
[totalAttentionMatrixSeconds, totalAttentionMatrix, endDistraction]  = deal(zeros(size(listOfSubjectFolders,2), 1)); % preallocating

%% 
disengageArray = cell(size(listOfSubjectFolders,1),1); % preallocating
for subjectNumber = 1:180 % go through the subjects
    cd(thePath);
    varname = listOfSubjectFolders{subjectNumber};
    cd(varname);
    contents = dir;
    contents = {contents(3:end).name};
    if ~isempty(contents)
        fileName = [varname '_EGT_Analysis.mat'];
        datName = ['dat_' varname];
        if exist(fileName, 'file')
            fileName = load(fileName, datName); 
            listOfSegmentNames = fieldnames(fileName.(datName)); 
            gazeMediaStorageArray = cell(1,21);
            for segmentNumber = 1:21 % all segments
                condition = listOfSegmentNames{segmentNumber};
                dat = fileName.(['dat_' varname]).(condition); 
                gazeMedia = dat.gazeonmedia;
                gazeMediaStorageArray{segmentNumber} = gazeMedia;
            end
            if strcmp(setting, 'all')
                chronologicalGazeMedia = vertcat(gazeMediaStorageArray{1}, gazeMediaStorageArray{16}, gazeMediaStorageArray{2}, gazeMediaStorageArray{13}, gazeMediaStorageArray{3}, gazeMediaStorageArray{14}, gazeMediaStorageArray{4}, gazeMediaStorageArray{12}, gazeMediaStorageArray{5}, gazeMediaStorageArray{15}, gazeMediaStorageArray{6}, gazeMediaStorageArray{17}, gazeMediaStorageArray{7}, gazeMediaStorageArray{18}, gazeMediaStorageArray{8}, gazeMediaStorageArray{21}, gazeMediaStorageArray{9}, gazeMediaStorageArray{20}, gazeMediaStorageArray{10}, gazeMediaStorageArray{19}, gazeMediaStorageArray{11});
            elseif strcmp(setting, 'social')
                chronologicalGazeMedia = vertcat(gazeMediaStorageArray{13}, gazeMediaStorageArray{3}, gazeMediaStorageArray{14}, gazeMediaStorageArray{4}, gazeMediaStorageArray{12}, gazeMediaStorageArray{5}, gazeMediaStorageArray{15});
                chronologicalGazeMedia = chronologicalGazeMedia(1:4920, :); % shortening to 41 seconds
            elseif strcmp(setting, 'nonSocial')
                chronologicalGazeMedia = gazeMediaStorageArray{16};
                chronologicalGazeMedia = chronologicalGazeMedia(1:4920, :); % shortening to 41 seconds
            end
            
            noNANs = find(~isnan(chronologicalGazeMedia(:,1)));

            %% Find disengagement areas
            disengage = zeros(size(noNANs,1),1); % preallocating
            
            for l = 1:size(noNANs,1)-1
                if noNANs(l+1) - noNANs(l) > toleranceThreshold % allow up to 24 sample gap
                    disengage(l) = noNANs(l) + 1;
                end
             end
            if size(noNANs,1) > 0 
                if noNANs(end)+toleranceThreshold < size(chronologicalGazeMedia,1) % allow up to the 24 sample gap at the end
                    disengage(size(disengage,1)) = noNANs(end); % In case they don't finish the segment looking at the media
                    endDistraction(subjectNumber) = 1; % to use to find the number of attention blocks
                end
            end
            disengage(disengage == 0) = []; % Get rid of all of the 0s so we just see where the disengagement points were
            

            %% Calculate total attention, including the NANs within the tolerance threshold
            if size(disengage,2) > 0
                if endDistraction(subjectNumber) == 0
                   disengage(size(disengage,1)+1,1) = size(chronologicalGazeMedia,1); % add in a distraction at the end of the block to use in calculating total amount of attention
                end
                disengageArray{subjectNumber,1} = size(disengage,1); 
                [start, finish] = deal(zeros(size(disengage))); % preallocating
                start(1) = noNANs(1);
                finish(1) = disengage(1);
                for a = 2:size(disengage,1)
                    start(a) = noNANs(find(noNANs>disengage(a-1), 1 )); % find the first non-NAN after they disengage
                    finish(a) = disengage(a);
                end
                totalAttentionMatrix(subjectNumber) = sum(finish-start)+1; 
            elseif size(disengage,1) == 0 && ~isempty(noNANs) % if they never look away enough for a distraction
                totalAttentionMatrix(subjectNumber) = size(chronologicalGazeMedia,1)-noNANs(1)+1; % this accounts for any ending NANs compared to noNANs(end)-noNANs(1)+1
            end
            totalAttentionMatrixSeconds(subjectNumber) = totalAttentionMatrix(subjectNumber)/sampleRate; % convert from samples to seconds
        end
    end
end

for disengageArrayElement = 1:numel(disengageArray)
    if isempty(disengageArray{disengageArrayElement})
        disengageArray{disengageArrayElement} = 0;
    end
end

attentionBlocksTotal = cell2mat(disengageArray);

%%

sumLookDurationTotal = sum(totalAttentionMatrixSeconds,2); % since we went unsegmented, it is the same as totalAttentionMatrixSeconds

totalALD_Continous = sumLookDurationTotal./attentionBlocksTotal;

