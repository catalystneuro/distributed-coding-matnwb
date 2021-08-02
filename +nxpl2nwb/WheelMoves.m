% function to convert wheel moves
function wheel_moves_behavior = WheelMoves(file_prefix, description, comments)

    arguments
        file_prefix (1, :) string
        description char = 'Detected wheel movements'
        comments char = 'No comments'
    end
    %% read files
    fname_wheel_movetype = strcat(file_prefix, 'wheelMoves.type.npy');
    fname_wheel_moveintervals = strcat(file_prefix, ...
                                            'wheelMoves.intervals.npy');
    wheel_moves_type = readNPY(fname_wheel_movetype);
    wheel_moves_intervals = readNPY(fname_wheel_moveintervals);
    wheel_moves_type = uint8(wheel_moves_type(:));
    %% create IntervalSeries
    wheel_moves_intervalseries = types.core.IntervalSeries(...
                            'timestamps', wheel_moves_intervals(:, 2), ...
                            'data', wheel_moves_type', ...
                            'description', description, ...
                            'comments', comments);
    wheel_moves_behavior = types.core.BehavioralEpochs('IntervalSeries', ...
                                            wheel_moves_intervalseries);
end
