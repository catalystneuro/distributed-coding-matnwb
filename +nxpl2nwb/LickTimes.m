% Function to read and convert lick times data
function lick_events = LickTimes(file_prefix, data_unit, description)
    arguments
        file_prefix (1, :) string = ''
        data_unit (1, :) char = 'Unknown'
        description char = 'Times of lick events'
    end
    %% Read data
    fname_lick_times = strcat(file_prefix, 'licks.times.npy');
    lick_timestamps = readNPY(fname_lick_times);

    lick_data = uint8(ones(length(lick_timestamps), 1));
    lick_timeseries = types.core.TimeSeries(...
                    'timestamps', lick_timestamps', ...
                    'data', lick_data, ...
                    'data_unit', data_unit, ...
                    'description', description);
    lick_events = types.core.BehavioralEvents('licks', ...
                                              lick_timeseries);
end
