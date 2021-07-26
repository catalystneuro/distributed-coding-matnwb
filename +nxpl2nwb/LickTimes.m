% Function to read lick times data and add as TimeSeries
function behavior_mod = LickTimes(behavior_mod, f_lk_ts, data_unit, description)
    arguments
        behavior_mod {mustBeA(behavior_mod, "types.core.ProcessingModule")}
        f_lk_ts (1, :) string
        data_unit (1, :) char = 'Unknown'
        description char = 'No description'
    end
    %% Read data
    lick_timestamps = readNPY(f_lk_ts);
    lick_data = ones(length(lick_timestamps), 1);
    lick_ts = types.core.TimeSeries(...
                    'timestamps', lick_timestamps', ...
                    'data', lick_data, ...
                    'data_unit', data_unit, ...
                    'description', description);
    lick_behavior = types.core.BehavioralEvents('timeseries', lick_ts);
    %% add to behavior processing module
    behavior_mod.nwbdatainterface.set(...
                    'BehavioralEvents', lick_behavior);
end
