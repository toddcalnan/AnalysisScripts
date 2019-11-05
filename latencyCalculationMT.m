%  Analysis of Eye Tracking data from the Sandwich Lady experiment.
% Determines if subject looked at the moving toy during the MT conditions
% and find the latency between when the toy starts moving and when the
% subject starts looking at the toy. 


%% Setup

clear
close all
thePath = 'C:\Users\tmc54\Documents\EyeTracking\DukeABCs_EGT';
cd(thePath)
mainFolder = dir;
listOfSubjectFolders = {mainFolder(3:25).name}; % first 2 files in directory are '.' and '..', so we just skip them and start at 3
nSubjects=size(listOfSubjectFolders,2);
samplesForFixation = 1; % for the Moving Toy conditions, we are only needing the subject to look at the toy for 1 sample to count as a fixation, decided by higher-ups


%% MT Condition 1
% Condition 1: Did they look at the moving toy at any time during the condition (1=yes,0=no)?
% Just do a simple sum() of the proper ROI column for each condition for
% each subject. If the sum is greater than 1, they looked at it

condition1 = zeros(nSubjects,4); % preallocating
for subjectIndex = 1:nSubjects % go through every subject
    subjectName = listOfSubjectFolders{subjectIndex}; % getting subject name from list of files
    cd(thePath)
    cd(subjectName) % go into the subject's folder
    matFileName = [subjectName '_EGT_Analysis.mat'];
    datStructName = ['dat_' subjectName]; % name of the structure that has the ROI data in it. 
    fileName = load(matFileName, datStructName); % load just the dat structure from the mat file
    listOfSegmentNames = fieldnames(fileName.(datStructName)); % all of the segment names, ie MTmonkey, JAmoose, etc. 
    for conditionIndex = 1:4 % go through all four of the MT conditions
        MTcondition = listOfSegmentNames{conditionIndex+17}; % conditionIndex+17 because MTmonkey is the first MT condition and it is the 18th field in the structure
        dat = fileName.(['dat_' subjectName]).(MTcondition); % structure that has all of the ROI variables, gazeEventType, validitycode, gazeonmedia, and trial numbers
        MTconditionROI = ['ROI' MTcondition(3:end) ]; % name of the specific Region of Interest we are looking at, should match the name of the MT condition, ie ROImonkey for MTmonkey
        ROIright = dat.(MTconditionROI); % column vector of doubles, all 0s or 1s. 0 means subject wasn't looking at the ROI during that trial, 1 means they were looking.
        if sum(ROIright)>= 1
            condition1(subjectIndex,conditionIndex) = 1; % if there was at least 1 '1' in the ROI column for the specific toy, condition 1 is true
        end
    end
end

condition1Total = sum(condition1,1);


%% Condition 2: 
% Were they looking at the toy during the last sample of the preceding DB condition? (1=yes,0=no)
% Changed this to look for if they were looking at the toy for the first
% sample of the MT condition, since there is a gap between DB and MT
% conditions

condition2 = zeros(nSubjects,4); % preallocating
for subjectIndex = 1:nSubjects 
    subjectName = listOfSubjectFolders{subjectIndex}; 
    cd(thePath)
    cd(subjectName) % go into the subject's folder
    fileName = [subjectName '_EGT_Analysis.mat']; 
    datStructName = ['dat_' subjectName]; % name of the structure that has the ROI data in it.
    fileName = load(fileName, datStructName); % load just the dat structure from the mat file
    listOfSegmentNames = fieldnames(fileName.(datStructName)); 
    for conditionIndex = 1:4 % go through all four of the MT conditions
        MTcondition = listOfSegmentNames{conditionIndex+17}; % conditionIndex+17 because MTmonkey is the first MT condition and it is the 18th field in the structure
        dat = fileName.(datStructName).(MTcondition); % structure that has all of the ROI variables, gazeEventType, validitycode, gazeonmedia, and trial numbers
        MTconditionROI = ['ROI' MTcondition(3:end) ]; % name of the specific Region of Interest we are looking at, should match the name of the MT condition, ie ROImonkey for MTmonkey
        if dat.(MTconditionROI)(1) == 1
            condition2(subjectIndex,conditionIndex) = 1;
        end

    end
end

condition2Total = sum(condition2,1);

%% Do they fixate on toy

[toyFixation, sampleBeforeFixation1, sampleBeforeFixation2] = deal(zeros(nSubjects,4));% preallocating
[startToys, stopToys, sampleBeforeFixationEvent] = deal(cell(nSubjects, 4)); % preallocating 
for subjectIndex = 1:nSubjects 
    subjectName = listOfSubjectFolders{subjectIndex}; 
    cd(thePath)
    cd(subjectName) % go into the subject's folder
    fileName = [subjectName '_EGT_Analysis.mat']; 
    datStructName = ['dat_' subjectName]; % name of the structure that has the ROI data in it.
    fileName = load(fileName, datStructName); % load just the dat structure from the mat file
    listOfSegmentNames = fieldnames(fileName.(datStructName)); 
    for conditionIndex = 1:4 % go through all four of the MT conditions
        MTcondition = listOfSegmentNames{conditionIndex+17};  % conditionIndex+17 because MTmonkey is the first MT condition and it is the 18th field in the structure
        dat = fileName.(['dat_' subjectName]).(MTcondition); % structure that has all of the ROI variables, gazeEventType, validitycode, gazeonmedia, and trial numbers
        MTconditionROI = ['ROI' MTcondition(3:end)]; % name of the specific Region of Interest we are looking at, should match the name of the MT condition, ie ROImonkey for MTmonkey
        ROIright = dat.(MTconditionROI);
        ROIall = dat.ROImoose + dat.ROImonkey + dat.ROIpenguin + dat.ROIrooster + dat.ROImouth + ... 
                 dat.ROIeyes +dat.ROIbody + dat.ROIhands;
        ROIwrong = ROIall-ROIright;
        gazeEventColumn = dat.gazeEventType; % what Tobii codes each sample as (Fixation, Saccade, Unclassified)
        validityCodeColumn = dat.validitycode;  
        gazeOnMediaColumn = dat.gazeonmedia; 
        if sum(ROIright)>= samplesForFixation
            [toyFixation(subjectIndex, conditionIndex), startToys{subjectIndex, conditionIndex}, stopToys{subjectIndex,conditionIndex}] = determineFixation(ROIright, ROIall, ROIwrong, samplesForFixation, gazeEventColumn, validityCodeColumn);
            if startToys{subjectIndex,conditionIndex}{1}-1 > 0
                sampleBeforeFixation1(subjectIndex,conditionIndex) = gazeOnMediaColumn(startToys{subjectIndex,conditionIndex}{1}-1,1); % for use in condition 3
                sampleBeforeFixation2(subjectIndex,conditionIndex) = gazeOnMediaColumn(startToys{subjectIndex,conditionIndex}{1}-1,2); % for use in condition 3
                sampleBeforeFixationEvent(subjectIndex,conditionIndex) = gazeEventColumn(startToys{subjectIndex,conditionIndex}{1}-1); % for use in condition 3
            end
        end
    end
end

toyFixationTotal = sum(toyFixation,1);

%% Condition 3: 
% Is there at least 1 sample on the media before the first sample they look at the toy? (1=yes,0=no) 

condition3 = zeros(nSubjects,4); % preallocating

% check to see if the sample immediately prior to the fixation is on the
% media

for m = 1:numel(toyFixation)
    isLooking = (toyFixation(m) == 1) && (~isnan(sampleBeforeFixation1(m)) && ~isnan(sampleBeforeFixation2(m)));
    if isLooking || ~strcmp(sampleBeforeFixationEvent(m), 'Unclassified') 
        condition3(m) = 1;
    end
end

condition3Total = sum(condition3,1);
%% Variable 1: 
% Are conditions 1&3 met but not 2 (1=yes,0=no)?

conditionsMatch = zeros(nSubjects,4);
for m = 1:numel(conditionsMatch)
    if condition1(m) == 1 && condition2(m) == 0 && condition3(m) == 1
        conditionsMatch(m) = 1;
    end
end
conditionsMatchTotal = sum(conditionsMatch,1);
%% Variable 2:
% Latency: How long do they take to fixate on MT distractor (i.e., moving toy)?
latency = zeros(size(conditionsMatch));
for m=1:numel(conditionsMatch)
    if conditionsMatch(m) == 1
        latency(m) = startToys{m}{1};
    end
end

%% Variable 3:
% Fixation Time: How long do they stay on the MT distractor (i.e., moving toy)?
lengthOfFixationMultiple{size(conditionsMatch,1), 4} = [];
for m = 1:numel(conditionsMatch)
    if conditionsMatch(m) == 1
        for conditionIndex = 1:size(startToys{m},2)
            lengthOfFixationMultiple{m}{conditionIndex} = stopToys{m}{conditionIndex}-startToys{m}{conditionIndex};
        end
    end
end
           
lengthOfFixation = zeros(size(conditionsMatch));
for m = 1:numel(conditionsMatch)
    if conditionsMatch(m) == 1
        lengthOfFixation(m) = stopToys{m}{1}-startToys{m}{1};
    end
end



%% Convert everything to milliseconds
sampleRate = 120; 
lengthOfFixationMilliseconds = zeros(size(lengthOfFixation));
for m = 1:numel(lengthOfFixation)
    lengthOfFixationMilliseconds(m) = (lengthOfFixation(m)/sampleRate)*1000;
end


latencyMilliseconds = zeros(size(latency));
for m = 1:numel(latency)
    latencyMilliseconds(m) = (latency(m)/sampleRate)*1000;
end

latencyMilliseconds(latencyMilliseconds==0) = NaN; % getting rid of zeros in the final result
latencyMilliseconds = round(latencyMilliseconds);
lengthOfFixationMilliseconds(lengthOfFixationMilliseconds==0) = NaN; % getting rid of zeros in the final result 
lengthOfFixationMilliseconds = round(lengthOfFixationMilliseconds);

%% Combine output variables and save the combination as an Excel file
allVariablesOutput = [conditionsMatch, latencyMilliseconds, lengthOfFixationMilliseconds];
cd(thePath)
xlswrite('allVariablesOutputMT.xlsx', allVariablesOutput);

%% Split variables into individual text files (1 text file per subject, 1 row, 12 columns)
for m = 1:size(allVariablesOutput,1)
    outputFileName = [listOfSubjectFolders{m} '_MT_Variables'];
    cd(thePath)
    cd(listOfSubjectFolders{m})
    fid = fopen(outputFileName, 'w');
    fprintf(fid, '%f ', allVariablesOutput(m,:));
    fclose(fid);
end

