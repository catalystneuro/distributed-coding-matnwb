% Function to read Lick piezo data files and add to a TimeSeries object
function lp_timeseries = LickPiezo(file_prefix, dataunit, description)
    arguments
        file_prefix (1, :) string = ''
        dataunit char = 'Unknown'
        description char = 'Voltage values from a thin-film piezo connected to the lick spout'
    end
    %% strcat(file_prefix, 'face.motionEnergy.npy')
    fname_lickpiezo_raw = strcat(file_prefix, 'lickPiezo.raw.npy');
    fname_lickpiezo_timestamps = strcat(file_prefix, ...
                                         'lickPiezo.timestamps.npy');

    lickpiezo_raw = readNPY(fname_lickpiezo_raw);
    lickpiezo_timestamps = readNPY(fname_lickpiezo_timestamps);
    lickpiezo_rate = nxpl2nwb.Rate(lickpiezo_timestamps);
    lp_timeseries = types.core.TimeSeries(...
                'starting_time', lickpiezo_timestamps(1, 2), ...
                'starting_time_rate', lickpiezo_rate, ...
                'data', lickpiezo_raw', ...
                'data_unit', dataunit, ...
                'description', description);
end
