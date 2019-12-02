% Calculate the average look duration of each eye tracking subject
% Input: the path should contain each subject's analysis folder containing
% the EGT_Analysis mat file. 
% Output: an Excel file containing the average look duration for each
% subject, for each condition

close all
clear
thePath = 'C:\Users\tmc54\Documents\EyeTracking\DukeACT_EGT\T1Background';
cd(thePath)
mainFolder = dir;
listOfSubjectFolders = {mainFolder(3:end).name}; %3:end means that it will start with the first subject and end with the last
sampleRate = 120; % sampling rate of the Tobii system
toleranceThreshold = 24; % how many samples we allow before calling something a distraction
setting = 'all'; % 'social', 'nonSocial', 'all' are the options
[totalAttentionMatrixSeconds, totalAttentionMatrix, endDistraction]...
    = deal(zeros(size(listOfSubjectFolders,2), 1)); % preallocating

%% 
disengageArray = cell(size(listOfSubjectFolders,1),1); % preallocating
for subjectNumber = 1:180 % go through the subjects
    cd(thePath);
    subjectName = listOfSubjectFolders{subjectNumber};
    cd(subjectName);
    contents = dir;
    contents = {contents(3:end).name}; % look at the contents of the subject's folder
    if ~isempty(contents) % if the subject's folder isn't empty
        fileName = [subjectName '_EGT_Analysis.mat']; % name of the subject's analyzed mat file
        datName = ['dat_' subjectName]; % we just need the 'dat' variable
        if exist(fileName, 'file') % if the analysis mat file exists
            fileName = load(fileName, datName);  % load the dat variable from the subject's analyzed mat file
            listOfSegmentNames = fieldnames(fileName.(datName)); % a list of all the fields in the analyzed mat file; we expect 21 fields, 1 per segment
            gazeMediaStorageArray = cell(1,size(listOfSegmentNames,2)); % preallocating
            for segmentNumber = 1:size(listOfSegmentNames,2) % go through all segments
                condition = listOfSegmentNames{segmentNumber};
                conditionData = fileName.(['dat_' subjectName]).(condition); % pull out the data for the condition we are looking at
                gazeMedia = conditionData.gazeonmedia; % pull out the gaze media field for the current condition
                gazeMediaStorageArray{segmentNumber} = gazeMedia; % save gaze media data to the storage array
            end
            if strcmp(setting, 'all') % look at all conditions
                chronologicalGazeMedia = vertcat(gazeMediaStorageArray{1}, gazeMediaStorageArray{16}, gazeMediaStorageArray{2}, gazeMediaStorageArray{13}, gazeMediaStorageArray{3}, gazeMediaStorageArray{14}, gazeMediaStorageArray{4}, gazeMediaStorageArray{12}, gazeMediaStorageArray{5}, gazeMediaStorageArray{15}, gazeMediaStorageArray{6}, gazeMediaStorageArray{17}, gazeMediaStorageArray{7}, gazeMediaStorageArray{18}, gazeMediaStorageArray{8}, gazeMediaStorageArray{21}, gazeMediaStorageArray{9}, gazeMediaStorageArray{20}, gazeMediaStorageArray{10}, gazeMediaStorageArray{19}, gazeMediaStorageArray{11});
            elseif strcmp(setting, 'social')
                chronologicalGazeMedia = vertcat(gazeMediaStorageArray{13}, gazeMediaStorageArray{3}, gazeMediaStorageArray{14}, gazeMediaStorageArray{4}, gazeMediaStorageArray{12}, gazeMediaStorageArray{5}, gazeMediaStorageArray{15});
                chronologicalGazeMedia = chronologicalGazeMedia(1:4920, :); % shortening to 41 seconds
            elseif strcmp(setting, 'nonSocial')
                chronologicalGazeMedia = gazeMediaStorageArray{16};
                chronologicalGazeMedia = chronologicalGazeMedia(1:4920, :); % shortening to 41 seconds
            end
            
            noNANs = find(~isnan(chronologicalGazeMedia(:,1))); % make a vector of where the gaze media is not a NaN, meaning Tobii had a lock on the eyes

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
            if size(disengage,2) > 0 % If there is a disengagement point
                if endDistraction(subjectNumber) == 0 % If we don't end with a distraction
                   disengage(size(disengage,1)+1,1) = size(chronologicalGazeMedia,1); % add in a distraction at the end of the block to use in calculating total amount of attention
                end
                disengageArray{subjectNumber,1} = size(disengage,1); % how many disengagement points there are for each subject
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

