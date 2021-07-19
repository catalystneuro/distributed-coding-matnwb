function behavior_mod = WheelMoves(behavior_mod, f_whl_moves_type, f_whl_moves_int, ...
                                   description, comments)
    % add wheel moves to BehavioralEpochs to behavior module
    wheel_moves_type = readNPY(f_whl_moves_type);
    wheel_moves_int = readNPY(f_whl_moves_int);
    wheel_moves_int = ceil(wheel_moves_int(:));

    wheel_moves_is = types.core.IntervalSeries(...
                        'timestamps', wheel_moves_int, ...
                        'data', wheel_moves_type', ...
                        'description', description, ...
                        'comments', comments);
    wheel_moves_beh = types.core.BehavioralEpochs('intervalseries', wheel_moves_is);
    behavior_mod.nwbdatainterface.set(...
                    'BehavioralEpochs', wheel_moves_beh);
end
