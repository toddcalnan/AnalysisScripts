% This is the master script to run after the Spontaneous conditions have been run through HAPPE 
% This script expects a mat file generated after inattention coding has been done, 
% the evt file generated after inattention coding has been done,
% and the processed mat file from HAPPE all in one folder. 
% Folder name should be the subject's ID. 
% Output will be a set of spectral plots, one for each Spontaneous
% condition

%% Load up evt file and scan it into a variable

clear
close all
inatLineLength = 64; % Number of characters from the starting 'i' in 'inat' to the last digit of the duration
motoLineLength = 68; % Number of characters from the starting 'm' in 'moto' to the last digit of the duration
soclLineLength = 53; 
toyLineLength = 53;
restLineLength = 53;
toysDuration = 60.990; % E-Prime run time in seconds
socialDuration = 65.750; % E-Prime run time in seconds
bubblesDuration = 60.000;  % E-Prime run time in seconds
thePath = 'home/tcalnan/Documents/MATLAB';
cd(thePath)
mainFolder = dir;
listOfSubjectFolders = {mainFolder(3:end).name}; % 3:end means that it will start with the first subject and end with the last
for subjectNumber = 1:size(listOfSubjectFolders,2)
    subjectName = listOfSubjectFolders{subjectNumber};
    cd(subjectName);
    fileID = fopen([subjectName '_1.evt'],'r');
    file=fgetl(fileID);
    while ~feof(fileID) % tests for end of file
        file = [file fgetl(fileID)]; % I would like to preallocate this, but unsure of how to do that, since we can't see how many lines this file is before this line of code
    end
    fclose(fileID);

    %% Pull out inat and moto lines

    inatStartPositions = strfind(file, 'inat'); % find 'inat' in the file
    motoStartPositions = strfind(file, 'moto'); % find 'moto' in the file
    soclStartPosition = strfind(file, 'socl');
    toysStartPosition = strfind(file, 'toy+');
    restStartPosition = strfind(file, 'rest');
    restStartPosition = restStartPosition(2); % since rest is the name of the experiment, rest is one of the first lines. We want the second rest line, since that is the actual spontaneous event
    
    soclLine = file(soclStartPosition:soclStartPosition + soclLineLength);
    toyLine = file(toysStartPosition:toysStartPosition + toyLineLength);
    restLine = file(restStartPosition:restStartPosition + restLineLength);

    % I would like to combine these loops, but the moto lines are slightly longer than the inat lines
    inatLines = cell(size(inatStartPositions,2),1); % preallocating
    if ~isempty(inatStartPositions)
        for inatNumber = 1:size(inatStartPositions,2)
            inatLines{inatNumber,1} = file(inatStartPositions(inatNumber):inatStartPositions(inatNumber)+inatLineLength); 
        end
    end
    motoLines = cell(size(motoStartPositions,2),1); % preallocating
    if ~isempty(motoStartPositions)
        for motoNumber = 1:size(motoStartPositions,2)
            motoLines{motoNumber,1} = file(motoStartPositions(motoNumber):motoStartPositions(motoNumber)+motoLineLength);
        end
    end

    combinedEventLines = [inatLines; motoLines];

    %% Extract flags, start time, and end time of each event. 
    % All of these could be put into one cell array if need be
    % Using the 'end' conditions because the moto and inat lines have different lengths

    [flags, start, duration] = deal(cell(1, size(combinedEventLines,1))); % preallocating
    for index = 1:size(combinedEventLines, 1)
        flags{index} = combinedEventLines{index}(1:4);
        start{index} = combinedEventLines{index}(end-27:end-12);
        duration{index} = combinedEventLines{index}(end-11:end);
    end

    soclStart = soclLine(26:40);
    toyStart = toyLine(26:40);
    restStart = restLine(26:40);
    %% Convert start time and duration to samples from start of recording
    % hour(duration) pulls out just the hours from the duration
    % minute(duration) pulls out just the minutes from the duration
    % second(duration) pulls out just the seconds (and decimals) from the duration
 
    totalTimeDuration = (hour(duration)*360) + (minute(duration)*60) + second(duration);
    totalTimeStart = (hour(start)*360) + (minute(start)*60) + second(start);
    totalTimeStop = totalTimeStart + totalTimeDuration;
    
    soclStartTime = (hour(soclStart)*360) + (minute(soclStart)*60) + second(soclStart); 
    toyStartTime = (hour(toyStart)*360) + (minute(toyStart)*60) + second(toyStart);
    restStartTime = (hour(restStart)*360) + (minute(restStart)*60) + second(restStart);
    
    soclStopTime = soclStartTime + socialDuration;
    toyStopTime = toyStartTime + toysDuration;
    restStopTime = restStartTime + bubblesDuration;
    %% Find out what epochs these events happen in

    startEpochs = floor(totalTimeStart);
    stopEpochs = floor(totalTimeStop);
    
    soclStartEpoch = floor(soclStartTime);
    toyStartEpoch = floor(toyStartTime);
    restStartEpoch = floor(restStartTime);
    
    soclStopEpoch = floor(soclStopTime);
    toyStopEpoch = floor(toyStopTime);
    restStopEpoch = floor(restStopTime);
    
    badEvtEpochs = [];
    for index = 1:size(startEpochs,2)
        badEvtEpochs = [badEvtEpochs startEpochs(index):stopEpochs(index)];
    end

    badEvtEpochs = sort(unique(badEvtEpochs));
    badEvtEpochs = badEvtEpochs+1; % so we are starting at epoch 1, not epoch 0
    %% Start of Spontaneous Segmenter section

    %% Load analyzed HAPPE data and create seperate arrays for each Spontaneous segment 
    load([subjectName '_processed.mat']) % loads in a variable named EEG

    badEpochsHAPPE = find(EEG.rejectedSegments.rejglobal);

    combinedBadEpochs = [badEpochsHAPPE badEvtEpochs]; 
    combinedBadEpochs = sort(unique(combinedBadEpochs));

    % Need the +1s in the following chunk to avoid index = 0 issues
    badEpochsToys = intersect(toyStartEpoch:toyStopEpoch, combinedBadEpochs) - toyStartEpoch + 1; 
    badEpochsSocial = intersect(soclStartEpoch:soclStopEpoch, combinedBadEpochs) - soclStartEpoch + 1;
    badEpochsRest = intersect(restStartEpoch:restStopEpoch, combinedBadEpochs) - restStartEpoch + 1;

    fieldTripData = eeglab2fieldtrip(EEG, 'preprocessing', 'none'); % convert to fieldtrip format

    % Pulling out appropriate epochs for each Spontaneous condition
    toysData = fieldTripData.trial(toysStartEpoch:toysStopEpoch);
    socialData = fieldTripData.trial(socialStartEpoch:socialStopEpoch);
    restData = fieldTripData.trial(restStartEpoch:restStopEpoch);

    % Removing bad epochs
    toysData(badEpochsToys) = [];
    socialData(badEpochsSocial) = [];
    restData(badEpochsRest) = [];

    %% Build fieldtrip-type structures for each condition so spectral plots can be generated 
    toysDataStruct.trial = toysData;
    toysDataStruct.label = fieldTripData.label;
    toysDataStruct.elec = fieldTripData.elec;
    toysDataStruct.time = fieldTripData.time(1:size(toysData,2));
    toysDataStruct.cfg = fieldTripData.cfg;
    toysDataStruct.fsample = fieldTripData.fsample;

    socialDataStruct.trial = socialData;
    socialDataStruct.label = fieldTripData.label;
    socialDataStruct.elec = fieldTripData.elec;
    socialDataStruct.time = fieldTripData.time(1:size(socialData,2));
    socialDataStruct.cfg = fieldTripData.cfg;
    socialDataStruct.fsample = fieldTripData.fsample;

    restDataStruct.trial = restData;
    restDataStruct.label = fieldTripData.label;
    restDataStruct.elec = fieldTripData.elec;
    restDataStruct.time = fieldTripData.time(1:size(restData,2));
    restDataStruct.cfg = fieldTripData.cfg;
    restDataStruct.fsample = fieldTripData.fsample;

    %% Plot each Spontaneous condition's spectral power 

    %% generate spectral data from fieldtrip formatted data 
    cfg = [];
    cfg.method = 'mtmfft';
    cfg.pad    = 'maxperlen';
    cfg.taper  = 'hanning';
    cfg.foilim= [0 150];
    cfg.trials = 'all';
    cfg.output = 'powandcsd';
    cfg.keeptrials = 'yes';
    cfg.channel = (1:123)';

    [powerToys] = ft_freqanalysis(cfg,toysDataStruct);
    [powerSocial] = ft_freqanalysis(cfg,socialDataStruct);
    [powerRest] = ft_freqanalysis(cfg,restDataStruct);

    frequenciesToys=powerToys.freq;
    powerSpectrumToys=powerToys.powspctrm;
    averagePowerSpectrumToys=squeeze(mean(powerSpectrumToys,1));

    frequenciesSocial=powerSocial.freq;
    powerSpectrumSocial=powerSocial.powspctrm;
    averagePowerSpectrumSocial=squeeze(mean(powerSpectrumSocial,1));

    frequenciesRest=powerRest.freq;
    powerSpectrumRest=powerRest.powspctrm;
    averagePowerSpectrumRest=squeeze(mean(powerSpectrumRest,1));

    % Conversion from dB to microvolts squared courtesy of https://sccn.ucsd.edu/pipermail/eeglablist/2008/002449.html
    mvSquaredToys = 10^(averagePowerSpectrumToys/10);
    mvSquaredSocial = 10^(averagePowerSpectrumSocial/10);
    mvSquaredRest = 10^(averagePowerSpectrumRest/10);

    %% Generate spectral plot
    figure;
    plot(frequenciesToys(1:41),mvSquaredToys(:,1:41));
    axis tight; xlabel('Frequency, Hz'); ylabel('\mu V^2'); title([ subjectName ' Toys Power Spectrum: ' num2str(size(toysData,2)) ' trials']); grid on;
    savefig([subjectName '_ToysPowerSpectrum.fig'])

    figure;
    plot(frequenciesSocial(1:41),mvSquaredSocial(:,1:41));
    axis tight; xlabel('Frequency, Hz'); ylabel('\mu V^2'); title([ subjectName ' Social Power Spectrum: ' num2str(size(socialData,2)) ' trials']); grid on;
    savefig([subjectName '_SocialPowerSpectrum.fig'])

    figure;
    plot(frequenciesRest(1:41),mvSquaredRest(:,1:41));
    axis tight; xlabel('Frequency, Hz'); ylabel('\mu V^2'); title([ subjectName ' Resting Power Spectrum: ' num2str(size(restData,2)) ' trials']); grid on;
    savefig([subjectName '_RestingPowerSpectrum.fig'])
end