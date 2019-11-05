%  Analysis of Eye Tracking data from the Sandwich Lady experiment.
%  Determines if subject looked at the actress at the beginning of the JA
%  condition, then followed her attention to the toy she is looking at. 

clear % clear any variables in the workspace
close all
thePath = 'C:\Users\tmc54\Documents\EyeTracking\SegmentedEGTData';
cd(thePath)
mainFolder = dir;
listOfSubjectFolders = {mainFolder(3:end).name}; % first 2 files in directory are '.' and '..', so we just skip them and start at 3
[actressFixation, toysFixation] = deal(zeros(size(listOfSubjectFolders,2), 4)); % preallocating; 4 is due to 4 JA segments
[startActress, stopActress] = deal(cell(size(listOfSubjectFolders,2), 4)); % preallocating 
samplesForFixation = 24; % what was decided upon to be the necessary number of samples to count as a fixation
for m = 1:size(listOfSubjectFolders,2) % go through all subjects in label
    SubjectName = listOfSubjectFolders{m};
    cd(thePath)
    cd(SubjectName)
    fileName = [SubjectName '_EGT_Analysis.mat'];
    datName = ['dat_' SubjectName]; 
    fileName = load(fileName, datName); % load only the dat structure in the EGT Analysis mat file, saves time and space
    listOfSegmentNames = fieldnames(fileName.(datName)); % list of segment names (ie, DB1, DB2, JAmonkey, MTrooster, etc)
    
%% Condition 1
% Did they look at the actress at any time during the segment for a certain number of samples (ok to blink during these samples) (1=yes,0=no)
    for n = 1:4 % go through each of the JA segments
        condition = listOfSegmentNames{n+11}; % which JA condition you are currently looking at. The +11 is to get you to the JA section. 1 to 11 are the DB conditions
        dat = fileName.(['dat_' SubjectName]).(condition); % the data for the JA condition in that subject's mat file
        ROIactress = dat.ROImouth + dat.ROIeyes +dat.ROIbody + dat.ROIhands; 
        ROIall = dat.ROImoose + dat.ROImonkey + dat.ROIpenguin + dat.ROIrooster + dat.ROImouth + dat.ROIeyes +dat.ROIbody + dat.ROIhands; 
        ROIwrong = ROIall-ROIactress;
        gazeEventColumn = dat.gazeEventType; % what Tobii codes each sample as (Fixation, Saccade, Unclassified)
        validityCodeColumn = dat.validitycode; 
        if sum(ROIactress)>= samplesForFixation % no point in determining fixation if they didn't look enough to get up to samples for fixaiton
            [actressFixation(m, n), startActress{m, n}, stopActress{m,n}] = determineFixation(ROIactress, ROIall, ROIwrong, samplesForFixation, gazeEventColumn, validityCodeColumn); % figure out if subject was fixating on actress, when they started fixating, and when they stop; start and stop can have multiple instances
        end
    end
end

%% Condition 2
% For each JA trial, each time child fixates on actress during JA condition, does the child then orient to and fixate on the JA target (taking no other path)?
% *i.e. For all instances of Target=1:  Was fixation on target preceded by fixation on the actress without fixation on distractors.

[startToys, stopToys] = deal(cell(size(listOfSubjectFolders,2), 4)); % preallocating

for m = 1:size(listOfSubjectFolders,2)
    SubjectName = listOfSubjectFolders{m};
    cd(thePath)
    cd(SubjectName)
    fileName = [SubjectName '_EGT_Analysis.mat']; 
    datName = ['dat_' SubjectName];
    fileName = load(fileName, datName); % load only the dat structure in the EGT Analysis mat file, saves time and space
    listOfSegmentNames = fieldnames(fileName.(datName)); % list of segment names (ie, DB1, DB2, JAmonkey, MTrooster, etc)
for n = 1:4
        condition = listOfSegmentNames{n+11};
        dat = fileName.(['dat_' SubjectName]).(condition);  % the data for the JA condition in that subject's mat file
        conditionROI = ['ROI' condition(3:end) ]; % which ROI we are looking at
        ROIright = dat.(conditionROI);
        ROIall = dat.ROImoose + dat.ROImonkey + dat.ROIpenguin + dat.ROIrooster + dat.ROImouth + dat.ROIeyes +dat.ROIbody + dat.ROIhands;
        ROIwrong = ROIall-ROIright;
        gazeEventColumn = dat.gazeEventType; % what Tobii codes each sample as (Fixation, Saccade, Unclassified)
        validityCodeColumn = dat.validitycode;
        if sum(ROIright)>= samplesForFixation
            [toysFixation(m, n), startToys{m, n}, stopToys{m,n}] = determineFixation(ROIright, ROIall, ROIwrong, samplesForFixation, gazeEventColumn, validityCodeColumn); % figure out if subject was fixating on toy, when they started fixating, and when they stop; start and stop can have multiple instances
        end
end

toysFixationTotal = sum(toysFixation,1);



end
fixationMatch = zeros(size(actressFixation)); % preallocating
for m = 1:numel(actressFixation) % using numel instead of using a nested for loop, makes things a little cleaner and faster
    if actressFixation(m) == 1 && toysFixation(m) == 1
        fixationMatch(m) = 1;
    end
end

fixationMatchTotal = sum(fixationMatch,1);

% Create a list of fixation start and stop times, that we will then sort.

listOfUnsortedFixations{size(fixationMatch,1),size(fixationMatch,2)} = []; % preallocating
for m = 1:numel(fixationMatch)
    if fixationMatch(m) == 1
        for p = 1:size(startActress{m},2)
            listOfUnsortedFixations{m}{p,1} = startActress{m}{p};
            listOfUnsortedFixations{m}{p,2} = 'startJAactress';
        end
        for q = 1:size(stopActress{m},2)
            listOfUnsortedFixations{m}{q+p,1} = stopActress{m}{q};
            listOfUnsortedFixations{m}{q+p,2} = 'stopJAactress';
        end
        for r = 1:size(startToys{m},2)
            listOfUnsortedFixations{m}{p+q+r,1} = startToys{m}{r};
            listOfUnsortedFixations{m}{p+q+r,2} = 'startJAtoys';
        end
        for s = 1:size(stopToys{m},2)
            listOfUnsortedFixations{m}{p+q+r+s,1} = stopToys{m}{s};
            listOfUnsortedFixations{m}{p+q+r+s,2} = 'stopJAtoys';
        end
    end
end

% sort the unsorted fixations to make the next step easier
sortedFixations{size(listOfUnsortedFixations,1),size(listOfUnsortedFixations,2)} = []; % preallocating
for m = 1:numel(listOfUnsortedFixations)
    sortedFixations{m} = sortrows(listOfUnsortedFixations{m});
end



% Check to see if subject fixates on the actress before fixating on the toy
% for each fixation time

actressFirst{size(fixationMatch,1),size(fixationMatch,2)} = []; % preallocating
for m = 1:numel(fixationMatch)
    if fixationMatch(m) == 1
        orderOfFixations = sortedFixations{m}(:,2);
        for t = 1:(size(orderOfFixations,1)-1) % minus 1 is a problem, work on this later
            if strcmp(orderOfFixations{t}, 'stopActress') && strcmp(orderOfFixations{t+1}, 'startToys') 
                actressFirst{m}{t} = 1;
            else
                actressFirst{m}{t} = 0;
            end
        end
    end
end

actressFirstTotal = zeros(size(actressFirst)); % preallocating
for m = 1:numel(actressFirst)
    actressFirstTotal(m) = sum(cell2mat(actressFirst{m}));
end

actressFirstTotalTotal = sum(actressFirstTotal);


% Did subject look at anything other than the actress or toy between the
% startJAactress and startJAtoys? 


distraction{size(actressFirst,1), size(actressFirst,2)} = []; % preallocating
for m = 1:size(actressFirst,1) % leaving this as nested for loops because of the JAcondition line, needs n until I find a workaround
    for n = 1:size(actressFirst,2)
        for l = 1:size(actressFirst{m,n},2)
            if actressFirst{m,n}{l} == 1 % checking to see if subject was looking at actress first before doing all this
                SubjectName = listOfSubjectFolders{m};
                cd(thePath)
                cd(SubjectName)
                fileName = [SubjectName '_EGT_Analysis.mat'];
                datName = ['dat_' SubjectName];
                fileName = load(fileName, datName); % load only the dat structure in the EGT Analysis mat file, saves time and space
                listOfSegmentNames = fieldnames(fileName.(datName)); % list of segment names (ie, DB1, DB2, JAmonkey, MTrooster, etc)
                condition = listOfSegmentNames{n+11};
                dat = fileName.(['dat_' SubjectName]).(condition);
                conditionROI = ['ROI' condition(3:end) ];
                ROIactress = dat.ROImouth + dat.ROIeyes +dat.ROIbody + dat.ROIhands;
                ROIactress = ROIactress(sortedFixations{m,n}{l}:sortedFixations{m,n}{l+1}); 
                ROItoy = dat.(conditionROI);
                ROItoy = ROItoy(sortedFixations{m,n}{l}:sortedFixations{m,n}{l+1});
                ROIall = dat.ROImoose + dat.ROImonkey + dat.ROIpenguin + dat.ROIrooster + dat.ROImouth + dat.ROIeyes +dat.ROIbody + dat.ROIhands;
                ROIall = ROIall(sortedFixations{m,n}{l}:sortedFixations{m,n}{l+1});
                gazeOnMediaColumn = dat.gazeonmedia;
                gazeOnMediaColumn = gazeOnMediaColumn(sortedFixations{m,n}{l}:sortedFixations{m,n}{l+1}, :);
                ROIright = ROIall - ROItoy - ROIactress;
                ROIwrong = ROIall-ROIright;
                gazeEventColumn = dat.gazeEventType;
                gazeEventColumn = gazeEventColumn(sortedFixations{m,n}{l}:sortedFixations{m,n}{l+1});
                distraction{m,n}{l} = determineDistraction(ROIright, gazeEventColumn, gazeOnMediaColumn, samplesForFixation, 1);
            end
        end
    end
end


distractionTotal = zeros(size(distraction)); % preallocating
for m = 1:numel(distraction)
    distractionTotal(m) = sum(cell2mat(distraction{m}));
end

distractionTotalTotal = sum(distractionTotal);


% Step 3: For each JA trial, for instances in which child meets the conditions of both fixating on actress and then fixating on JA target with no other path, how long was child looking at the actress before disengaging to shift gaze to the JA target? 
% NOTE: We only need that time variable for the very first time that they successfully completed both fixations (actress, then target).                
% In other words: 
%- If child has multiple instances of actress-target fixation pairs within a JA trial, we only need the time for the very first instance in which the child successfully fixated the actress and then the JA target. 
%- If child has multiple instances of fixation on the actress during JA trial, but only fixates the JA target after the third fixation on the actress, then we need disengagement time for that instance. That is their first successful actress-JAtarget fixation pair.


timeLookingAtActress = cell(size(distraction)); % preallocating 
for m = 1:numel(distraction)
    for n = 1:size(distraction{m},2)
        if distraction{m}{n} == 0 
            if distraction{m}{n} == 0
                timeLookingAtActress{m}{n} = sortedFixations{m}{n}-sortedFixations{m}{n-1};
            end
        end
    end
end

timeLookingAtActressFirst = cell(size(timeLookingAtActress)); % preallocating

for m =1:numel(timeLookingAtActress)
    if ~isempty(timeLookingAtActress{m})
        noDistractionFixations = find(~cellfun('isempty', timeLookingAtActress{m}));
        timeLookingAtActressFirst{m} = timeLookingAtActress{m}{noDistractionFixations(1)};
    else
        timeLookingAtActressFirst{m} = 0;
    end
end
timeLookingAtActressFirst = cell2mat(timeLookingAtActressFirst);