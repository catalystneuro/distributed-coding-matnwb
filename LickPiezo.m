function lp_timeseries = LickPiezo(f_lp_raw, f_lp_ts, data_unit, description)
    % add lick piezo to nwb acquisition
    lp_raw = readNPY(f_lp_raw);
    lp_timestamps = readNPY(f_lp_ts);
    lp_rate = Rate(lp_timestamps);
    lp_timeseries = types.core.TimeSeries(...
                'starting_time', lp_timestamps(1, 2), ...
                'starting_time_rate', lp_rate, ...
                'data', lp_raw', ...
                'data_unit', data_unit, ...
                'description', description);
end

function rate = Rate(timestamps)
    % calculate rate
    rate = (timestamps(2, 2) - timestamps(1, 2)) / (timestamps(2, 1));
end
