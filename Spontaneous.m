% function add spontaneous intervals to acquisition
function spont_ti = Spontaneous(f_spot_int)

    arguments
        f_spot_int (1, :) string
    end
    spont = readNPY(f_spot_int);
    start_time = spont(:, 1);
    stop_time = spont(:, 2);

    %% Create TimeIntervals object
    spont_ti = types.core.TimeIntervals(...
                'colnames', {'start_time', 'stop_time'}, ...
                'id', types.hdmf_common.ElementIdentifiers('data', 0:length(spont(:, 1))-1), ...
                'description', {'Intervals of sufficient duration when nothing '
                                'else is going on (no task or stimulus presentation'}, ...
                'start_time', types.hdmf_common.VectorData('data', ...
                    start_time, 'description', 'this is start time'), ...
                'stop_time', types.hdmf_common.VectorData('data', ...
                    stop_time, 'description','this is stop time'));
end
