% Function to add wheel position to nwb.acquisition
function wheel_ts = Wheel(f_whl_pos, f_whl_ts, data_unit, ...
                          data_conversion, description, comments)
    arguments
        f_whl_pos (1, :) string
        f_whl_ts (1, :) string
        data_unit char = 'Unknown'
        data_conversion double = 1
        description char = 'No description'
        comments char = 'No comments'
    end
    %% Read data files
    wheel_pos = readNPY(f_whl_pos);
    wheel_ts = readNPY(f_whl_ts);
    wheel_rate = Rate(wheel_ts);
    %% create TimeSeries object
    wheel_ts = types.core.TimeSeries(...
                'starting_time', wheel_ts(1, 2), ...
                'starting_time_rate', wheel_rate, ...
                'data', wheel_pos', ...
                'data_unit', data_unit, ...
                'data_conversion', data_conversion, ...
                'description', description, ...
                'comments', comments);
end

function rate = Rate(timestamps)
    % calculate rate
    rate = (timestamps(2, 2) - timestamps(1, 2)) / (timestamps(2, 1));
end
