function [nonNaNSaccades] = removeNaNSaccades(saccadeClusters)

nonNaNSaccades = cell(1,1); % Preallocating

% Look at each saccade cluster, see if the number of NaNs in that cluster
% is equal to the total size of the cluster. If no, we leave that cluster.
for index = 1:size(saccadeClusters,2)
    if ~(sum(cellfun(@isnan,saccadeClusters{index}(:,3))) == size(saccadeClusters{index},1))
        nonNaNSaccades{end+1} = saccadeClusters{index};
    end
end

% Remove empty cells, mainly the first cell
nonNaNSaccades = nonNaNSaccades(~cellfun('isempty',nonNaNSaccades)); 