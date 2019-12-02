% Calculate the velocity of each saccade cluster
% Input is a cell array of saccade clusters and the sampling rate, almost
% always 120
% Output is the velocity of the saccade cluster

function [velocity] = calculateSaccadeVelocity(saccadeClusters, sampleRate)

% Preallocate
[xStart, yStart, xEnd, yEnd, saccadeSize] = deal(zeros(size(saccadeClusters))); % preallocating

for index = 1:size(saccadeClusters,2)
    % Remove the NaNs from the start of the saccade
    if isnan(saccadeClusters{index}{1,3})
        while isnan(saccadeClusters{index}{1,3})
            saccadeClusters{index}(1,:) = [];
        end
    end
    
    % Remove the end NaNs from the saccade
    if isnan(saccadeClusters{index}{end,3})
        while isnan(saccadeClusters{index}{end,3})
            saccadeClusters{index}(end,:) = [];
        end
    end
    
    if size(saccadeClusters{index},1) > 1 % In case there is just one sample left after removing nans
        xStart(index) = saccadeClusters{index}{1,3}; % x position of first saccade sample in a cluster
        yStart(index) = saccadeClusters{index}{1,4}; % y position of first saccade sample in a cluster
    
        xEnd(index) = saccadeClusters{index}{end,3}; % x position of last saccade sample in a cluster
        yEnd(index) = saccadeClusters{index}{end,4}; % y position of last saccade sample in a cluster
        
        saccadeSize(index) = size(saccadeClusters{index},1); % Number of samples in the cluster
    end
end

% Calculate changes in x and y coordinates for each saccade cluster
delX = xEnd-xStart;
delY = yEnd-yStart;

% Convert saccadeSize to seconds
saccadeSizeSamples = saccadeSize/sampleRate;

% Calculate velocity
velocity = (delX+delY)./saccadeSizeSamples;

% Requiring size after nan removal in the above loop leaves us with some
% nans in velocity. This line removes those nans.
velocity = velocity(~isnan(velocity));


