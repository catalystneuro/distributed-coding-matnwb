% function add wheel moves to BehavioralEpochs to behavior module
function behavior_mod = WheelMoves(behavior_mod, f_whl_moves_type, ...
                                   f_whl_moves_int, description, comments)

    arguments
        behavior_mod {mustBeA(behavior_mod, "types.core.ProcessingModule")}
        f_whl_moves_type(1, :) string
        f_whl_moves_int(1, :) string
        description char = 'No description'
        comments char = 'No comments'
    end
    %% read files
    wheel_moves_type = readNPY(f_whl_moves_type);
    wheel_moves_int = readNPY(f_whl_moves_int);
    wheel_moves_int = ceil(wheel_moves_int(:));
    %% create IntervalSeries
    wheel_moves_is = types.core.IntervalSeries(...
                        'timestamps', wheel_moves_int, ...
                        'data', wheel_moves_type', ...
                        'description', description, ...
                        'comments', comments);
    wheel_moves_beh = types.core.BehavioralEpochs('intervalseries', ...
                                            wheel_moves_is);
    %%
    behavior_mod.nwbdatainterface.set(...
                    'BehavioralEpochs', wheel_moves_beh);
end
