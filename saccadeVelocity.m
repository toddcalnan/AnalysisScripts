% Expects a folder in thePath that has all of the segmented ACE EGT files,
% one file per subject. Output will be a single Excel file containing the
% list of subjects analyzed, max and mean saccade velocities for each of the 4
% conditions (DB, Sandwich, JA, MT) and the velocities of all saccades that
% start in one segment and end in another segment (referred to as mismatch
% in this script). 

% Velocities all in units of pixels per second. 
% Maximum velocities are the largest magnitude, so some maxima are negative. 

% This script only looks at saccades that take longer than one sample,
% since we can't calculate velocity from one point. 

clear

% What segment numbers are in what conditions
conditionNumbersDB = [1,3,5,7,9,11,13,15,17,19,21];
conditionNumbersJA = [4,6,8,10];
conditionNumbersSandwich = [2,12];
conditionNumbersMT = [14,16,18,20];

% Find subject folders and create subject list
thePath = 'C:\Users\tmc54\Desktop\ACE_EGT_Segmented';
cd(thePath)
mainFolder = dir;
listOfSubjectFolders = {mainFolder(3:end).name}; % 3:end means that it will start with the first subject and end with the last
[maxVelocityDB, meanVelocityDB, maxVelocitySandwich, meanVelocitySandwich, maxVelocityJA, meanVelocityJA, maxVelocityMT, meanVelocityMT] = deal(zeros(size(listOfSubjectFolders))); % Preallocating
velocityMismatch = cell(size(listOfSubjectFolders)); % Preallocating
sampleRate = 120; 
for subjectNumber = 63
    tic
    subjectName = listOfSubjectFolders{subjectNumber}(1:9);
    %%
    fileName = [subjectName '_segmented.xls'];
    [~, ~, raw]=xlsread(fileName); % This could include 'O:BL' as an additional input to reduce the number of columns, but tic toc shows that is slower for some reason
    raw = raw(2:end,:); % Remove the header
    originalDataArray = cell(size(raw,1),4); % Preallocating
    originalDataArray(:,1) = raw(:,15); % SegmentNumber
    originalDataArray(:,2) = raw(:, 43); % EventType
    originalDataArray(:,3) = raw(:, 63); % xPosition
    originalDataArray(:,4) = raw(:, 64); % yPosition

    saccadeRows = strfind(originalDataArray(:,2), 'Saccade'); % Find all the saccades 
    saccadeSampleNumbers = find(~cellfun(@isempty,saccadeRows)); % Return the sample numbers for where the saccades are

    saccadeEndPoints = find(diff(saccadeSampleNumbers)~=1); % Find the sample where one saccade ends and the next begins, look for jumps like 14,15,16,63
    saccadeEndPoints(end+1) = size(saccadeSampleNumbers,1); % Make sure we go to the last of the saccade samples
    
    % Segment data into individual saccades
    individualSaccadeClusters = cell(1,size(saccadeEndPoints,1)); % Preallocating
    saccadeRange = {saccadeSampleNumbers(1):saccadeSampleNumbers(saccadeEndPoints(1))}; % Samples between start and end point for the first saccade
    individualSaccadeClusters{1} = originalDataArray(saccadeRange{1},:); % Initial saccade
    for index = 1:(size(saccadeEndPoints,1)-1)
        saccadeRange = {saccadeSampleNumbers((saccadeEndPoints(index)+1)):saccadeSampleNumbers(saccadeEndPoints(index+1))}; % Samples between start and end point for each saccade
        individualSaccadeClusters{index+1} = originalDataArray(saccadeRange{1},:); % The +1 is needed to not overwrite the initial saccade cluster
    end

    %% Now that we have saccade clusters, find what segment each saccade starts and ends in
    [segmentStart, segmentEnd] = deal(zeros(size(individualSaccadeClusters))); % Preallocating
    [DB, sandwich, JA, MT] = deal(cell(size(individualSaccadeClusters))); % Preallocating
    for index = 1:size(individualSaccadeClusters,2)
        segmentStart(index) = individualSaccadeClusters{index}{1,1}; % What segment does the saccade start in
        segmentEnd(index) = individualSaccadeClusters{index}{end,1}; % What segment does the saccade end in
    end
    
    % Move saccades that are fully in one segment to that segment's array
    mismatch = cell(1,1); % Preallocating
    for index = 1:size(individualSaccadeClusters,2)
        if segmentStart(index) == segmentEnd(index) % Saccade starts and ends in the same segment
            if ismember(segmentStart(index), conditionNumbersDB)
                DB{index} = individualSaccadeClusters{index};
            elseif ismember(segmentStart(index), conditionNumbersSandwich)
                sandwich{index} = individualSaccadeClusters{index};
            elseif ismember(segmentStart(index), conditionNumbersJA)
                JA{index} = individualSaccadeClusters{index};
            elseif ismember(segmentStart(index), conditionNumbersMT)
                MT{index} = individualSaccadeClusters{index};
            end
        else
            mismatch{index} = individualSaccadeClusters{index}; % Saccade starts in one segment, then ends in another
        end
    end

    % Remove empty cells 
    DB = DB(~cellfun('isempty',DB));
    sandwich = sandwich(~cellfun('isempty',sandwich));
    JA = JA(~cellfun('isempty',JA));
    MT = MT(~cellfun('isempty',MT));
    mismatch = mismatch(~cellfun('isempty',mismatch));
    
    % Remove any saccades from mismatch that are made purely of nans
    mismatch = removeNaNSaccades(mismatch); 

    %% Deal with mismatches
    % Find where we go from one segment to another in each mismatch case
    % Match each half up with what condition they happened during 
    %(ie, first half in DB1, second half in Sandwich 1)
    [mismatchSegmentSplit, firstSegmentSaccade, secondSegmentSaccade] = deal(cell(size(mismatch))); % Preallocating
    for mismatchIndex = 1:size(mismatch,2)
        mismatchSegmentColumn = cell2mat(mismatch{1,mismatchIndex}(:,1));
        mismatchSegmentSplit{mismatchIndex} = find(diff(mismatchSegmentColumn)~=0); % Find where the change from one segment to the next occurs
        firstSegmentSaccade{mismatchIndex} = mismatch{1,mismatchIndex}(1:mismatchSegmentSplit{mismatchIndex},:); 
        secondSegmentSaccade{mismatchIndex} = mismatch{1,mismatchIndex}((mismatchSegmentSplit{mismatchIndex}+1):end,:);
        
        % Move the first part of the mismatched saccade to its appropriate
        % condtion
        if size(firstSegmentSaccade{1,mismatchIndex}) > 1 % We only care about saccades that have more than one sample
            if ismember(cell2mat(firstSegmentSaccade{1,mismatchIndex}(1)),conditionNumbersDB)
                DB{end+1} = firstSegmentSaccade{1,mismatchIndex};
            elseif ismember(cell2mat(firstSegmentSaccade{1,mismatchIndex}(1)),conditionNumbersSandwich)
                sandwich{end+1} = firstSegmentSaccade{1,mismatchIndex};
            elseif ismember(cell2mat(firstSegmentSaccade{1,mismatchIndex}(1)),conditionNumbersJA)
                JA{end+1} = firstSegmentSaccade{1,mismatchIndex};
            elseif ismember(cell2mat(firstSegmentSaccade{1,mismatchIndex}(1)),conditionNumbersMT)
                MT{end+1} = firstSegmentSaccade{1,mismatchIndex};
            end
        end
        
        % Move the second part of the mismatched saccade to its appropriate
        % condition
        if size(secondSegmentSaccade{1,mismatchIndex}) > 1
            if ismember(cell2mat(secondSegmentSaccade{1,mismatchIndex}(1)),conditionNumbersDB)
                DB{end+1} = secondSegmentSaccade{1,mismatchIndex};
            elseif ismember(cell2mat(secondSegmentSaccade{1,mismatchIndex}(1)),conditionNumbersSandwich)
                sandwich{end+1} = secondSegmentSaccade{1,mismatchIndex};
            elseif ismember(cell2mat(secondSegmentSaccade{1,mismatchIndex}(1)),conditionNumbersJA)
                JA{end+1} = secondSegmentSaccade{1,mismatchIndex};
            elseif ismember(cell2mat(secondSegmentSaccade{1,mismatchIndex}(1)),conditionNumbersMT)
                MT{end+1} = secondSegmentSaccade{1,mismatchIndex};
            end
        end
    end
%% Clean up condition arrays

    % Remove saccades that only last one sample. 
    % We can't calculate velocity with only one point.
    DB(cellfun('size',DB, 1)<2) = [];
    sandwich(cellfun('size',sandwich, 1)<2) = [];
    JA(cellfun('size',JA, 1)<2) = [];
    MT(cellfun('size',MT, 1)<2) = [];

    % Remove saccades that are only made up of NaNs for coordinates
    DB = removeNaNSaccades(DB);
    sandwich = removeNaNSaccades(sandwich);
    JA = removeNaNSaccades(JA);
    MT = removeNaNSaccades(MT);
    
    %% Calculate velocity from start and end coordinates and the saccade length
    % Velocity will be in units of pixels/second
    velocityDB = calculateSaccadeVelocity(DB, sampleRate);
    velocitySandwich = calculateSaccadeVelocity(sandwich, sampleRate);
    velocityJA = calculateSaccadeVelocity(JA, sampleRate);
    velocityMT = calculateSaccadeVelocity(MT, sampleRate);
    
    % Calculate the velocities of the mismatched saccades, if available 
    if ~isempty(mismatch)
        velocityMismatch{subjectNumber} = calculateSaccadeVelocity(mismatch, sampleRate);
    end
    %% Calculate max and mean velocity
    
    [~,indexMaxVelocityDB] = max(abs(velocityDB)); 
    maxVelocityDB(subjectNumber) = velocityDB(indexMaxVelocityDB);
    meanVelocityDB(subjectNumber) = mean(velocityDB);

    [~,indexMaxVelocitySandwich] = max(abs(velocitySandwich)); 
    maxVelocitySandwich(subjectNumber) = velocitySandwich(indexMaxVelocitySandwich);
    meanVelocitySandwich(subjectNumber) = mean(velocitySandwich);

    [~,indexMaxVelocityJA] = max(abs(velocityJA)); 
    maxVelocityJA(subjectNumber) = velocityJA(indexMaxVelocityJA);
    meanVelocityJA(subjectNumber) = mean(velocityJA);
    
    [~,indexMaxVelocityMT] = max(abs(velocityMT)); 
    maxVelocityMT(subjectNumber) = velocityMT(indexMaxVelocityMT);
    meanVelocityMT(subjectNumber) = mean(velocityMT);

    toc
end
%% Merge output variables to create an Excel spreadsheet

outputTable = table(listOfSubjectFolders', maxVelocityDB', maxVelocityJA', maxVelocityMT', maxVelocitySandwich', meanVelocityDB', meanVelocityJA', meanVelocityMT', meanVelocitySandwich', velocityMismatch');

header = {'subjectNames', 'maxVelocityDB', 'maxVelocityJA', 'maxVelocityMT', 'maxVelocitySandwich', 'meanVelocityDB', 'meanVelocityJA', 'meanVelocityMT', 'meanVelocitySandwich', 'velocityMismatch'};
outputTable.Properties.VariableNames = header;

cd('C:\Users\tmc54\Desktop');
writetable(outputTable, 'saccadeVelocityOutput.xlsx');