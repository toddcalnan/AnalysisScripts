function [fixation, startTimes, stopTimes] = determineFixation(targetColumn, totalColumn, wrongColumn, samplesForFixation, gazeEventColumn, validityCodeColumn)
[start, countTracker] = deal(zeros(1,size(targetColumn,1))); % preallocating
m=1; % initializing for while loop
count = 0; % initializing
fixation = 0; % initializing
countDouble4s = 0; % initializing
nDoubleFoursForInvalid = 30; % after 30 consecutive 4s in both eyes, we stop counting this as a fixation
while m<size(targetColumn,1)
    isValid = (validityCodeColumn(m,1) ~=4 || validityCodeColumn(m,2) ~=4); % data point is valid so long as both eyes are not 4s in Tobii
    isFixatingOnTarget = (targetColumn(m) == 1) && strcmp(gazeEventColumn(m), 'Fixation'); % counts as Fixation if Tobii calls it a fixation and there is a 1 in the specific ROI column
    if isFixatingOnTarget && m < size(targetColumn,1) && isValid  && countDouble4s < nDoubleFoursForInvalid 
        while (targetColumn(m) == 1 || totalColumn(m) == 0) && m < size(targetColumn,1) && strcmp(gazeEventColumn(m), 'Fixation') && countDouble4s <= 30
            if targetColumn(m) == 1
                start(m) = m;
                count = count + 1;
                countTracker(m) = count;
                countDouble4s = 0;
                if count >= samplesForFixation
                    fixation = 1;
                end
            end
            m = m+1;
        end
    end
    isFixatingOnNothing = (strcmp(gazeEventColumn(m), 'Fixation') && totalColumn(m) == 0); % if subject is just fixating on the background or off the screen
    if wrongColumn(m) == 1 || isFixatingOnNothing % if they look at any of the other ROIs or Fixate on nothing, reset the count 
       count = 0;
    elseif (validityCodeColumn(m,1) == 4 && validityCodeColumn(m,2) == 4) 
        countDouble4s = countDouble4s + 1;
        if countDouble4s >= 30
            count = 0;
            countDouble4s = 0;
        end
    end
    m=m+1;
end            

foundOnes = find(countTracker == 1);

startTimes{size(foundOnes,2)} = []; % preallocating 
stopTimes{size(foundOnes,2)} = []; % preallocating 
startTestFixations{size(foundOnes,2)} = []; % preallocating 
for a = 1:size(foundOnes,2)
    if ~exist('foundOnes', 'var')
        startTimes{a} = 0;
        stopTimes{a} = 0;
    end
    if a+1>size(foundOnes,2)
        startTestFixations{a} = countTracker(foundOnes(a):end); 
    else
        startTestFixations{a} = countTracker(foundOnes(a):foundOnes(a+1)-1);
    end
    [~, index] = max(startTestFixations{a});
    startTestFixations{a} = startTestFixations{a}(1:index);
    startTimes{a} = foundOnes(a);
    stopTimes{a} = index+startTimes{a} - 1; 
end
