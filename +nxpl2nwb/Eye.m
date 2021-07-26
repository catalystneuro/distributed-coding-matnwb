% Function to add eye position and pupil tracking to NWB behavioral
% processing module
function behavior_mod = Eye(behavior_mod, ...
                            f_eye_timestamps, f_eye_area, f_eye_xy_pos, ...
                            ts_data_unit, ts_description, ts_comments, ...
                            xy_data_unit, xy_description, xy_comments)
    arguments
        behavior_mod {mustBeA(behavior_mod, "types.core.ProcessingModule")}
        f_eye_timestamps (1,:) string
        f_eye_area (1, :) string
        f_eye_xy_pos (1, :) string
        ts_data_unit char = 'Unknown'
        ts_description char = 'Time series denoting Pupil movements'
        ts_comments char = 'No comments'
        xy_data_unit char = 'Unknown'
        xy_description char = 'Time series denoting eye xy positions'
        xy_comments char = 'No comments'
    end
    %% Read .npy files for eye timestamps, eye area and eye xy positions
    eye_timestamps = readNPY(f_eye_timestamps);
    eye_area = readNPY(f_eye_area);
    eye_xy_pos = readNPY(f_eye_xy_pos);
    % create TimeSeries object for eye area
    pupil = types.core.TimeSeries('timestamps',  eye_timestamps(:, 2), ...
                 'data', eye_area', ...
                 'data_unit', ts_data_unit, ...
                 'description', ts_description, ...
                 'comments', ts_comments);
    % create TimeSeries for eye xy s
    eye_xy = types.core.TimeSeries('timestamps',eye_timestamps(:, 2), ...
                'data', eye_xy_pos, ...
                'data_unit', xy_data_unit, ...
                'description', xy_description, ...
                'comments', xy_comments);
    %% add both TimeSeries objects to PupilTracking and add to behavior
    % module
    pupil_track = types.core.PupilTracking('timeseries', [pupil, eye_xy]);
    behavior_mod.nwbdatainterface.set(...
                    'PupilTracking', pupil_track);
end
