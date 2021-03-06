% function to convert spontaneous intervals
function spontaneous_timeintervals = Spontaneous(file_prefix, description)

    arguments
        file_prefix (1, :) string = ''
        description char = 'Intervals of duration when no stimuli or task'
    end
    %% Read data file
    fname_spontaneous = strcat(file_prefix, 'spontaneous.intervals.npy');
    spontaneous = readNPY(fname_spontaneous);
    start_time = spontaneous(:, 1);
    stop_time = spontaneous(:, 2);

    %% Create TimeIntervals object
    spontaneous_timeintervals = types.core.TimeIntervals(...
                'colnames', {'start_time', 'stop_time'}, ...
                'id', ...
                types.hdmf_common.ElementIdentifiers('data', ...
                                            0:length(spontaneous(:, 1))-1), ...
                'description', description, ...
                'start_time', types.hdmf_common.VectorData('data', ...
                    start_time, 'description', 'this is start time'), ...
                'stop_time', types.hdmf_common.VectorData('data', ...
                    stop_time, 'description','this is stop time'));
end
