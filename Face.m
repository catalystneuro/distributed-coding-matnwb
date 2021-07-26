% Convert Face energy behavioral data and add behavior processing module
function behavior_mod = Face(behavior_mod, ...
                             f_face_motion_energy, f_face_timestamps, ...
                             data_unit, description, comments)
    arguments
        behavior_mod {mustBeA(behavior_mod, "types.core.ProcessingModule")}
        f_face_motion_energy (1, :) string
        f_face_timestamps (1, :) string
        data_unit char = 'Unknown'
        description char = 'No description'
        comments char = 'No comments'
    end
    %% Read data files and create TimeSeries object
    face_motion_energy = readNPY(f_face_motion_energy);
    face_timestamps = readNPY(f_face_timestamps);
    face_rate = Rate(face_timestamps);
    face_energy = types.core.TimeSeries(...
        'data', face_motion_energy', ...
        'data_unit', data_unit, ...
        'starting_time', face_timestamps(1, 2), ...
        'starting_time_rate', face_rate, ...
        'description', description, ...
        'comments', comments);
    %% create BehavioralTimeSeries object face energy and add to
    %  behavior processing module
    face_interface = types.core.BehavioralTimeSeries('timeseries', face_energy);
    behavior_mod.nwbdatainterface.set(...
                    'BehavioralTimeSeries', face_interface);
end

function rate = Rate(timestamps)
    arguments
        timestamps (2, :) double
    end
    %% function to calculate rate
    rate = (timestamps(2, 2) - timestamps(1, 2)) / (timestamps(2, 1));
end
