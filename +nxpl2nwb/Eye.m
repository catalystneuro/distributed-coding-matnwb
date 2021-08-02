% Function to convert area and xy coordinates of pupil
function [pupil_tracking, eye_tracking] = Eye(file_prefix, ...
                                            pupil_track_dataunit, pupil_track_description, ...
                                            pupil_track_comments, ...
                                            spatial_dataunit, spatial_description, ...
                                            spatial_comments)
    arguments
        % prefix of the file / identifier to locate particular session
        file_prefix (1, :) string = ''
        pupil_track_dataunit char = 'Unknown'
        pupil_track_description char = 'Time series denoting Pupil movements'
        pupil_track_comments char = 'No comments'
        spatial_dataunit char = 'Unknown'
        spatial_description char = 'Time series denoting eye xy positions'
        spatial_comments char = 'No comments'
    end
    %% Read .npy files for eye timestamps, eye area and eye xy positions

    % prepare file names
    fname_eye_timestamps = strcat(file_prefix, 'eye.timestamps.npy');
    fname_eye_area = strcat(file_prefix, 'eye.area.npy');
    fname_eye_xy_pos = strcat(file_prefix, 'eye.xyPos.npy');

    % read data files
    eye_timestamps = readNPY(fname_eye_timestamps);
    eye_area = readNPY(fname_eye_area);
    eye_xy_pos = readNPY(fname_eye_xy_pos);

    % create TimeSeries object for eye area
    pupil = types.core.TimeSeries('timestamps',  eye_timestamps(:, 2), ...
                 'data', eye_area', ...
                 'data_unit', pupil_track_dataunit, ...
                 'description', pupil_track_description, ...
                 'comments', pupil_track_comments);
    % create TimeSeries for eye xy s
    eye_xy = types.core.SpatialSeries('timestamps',eye_timestamps(:, 2), ...
                'data', eye_xy_pos', ...
                'data_unit', spatial_dataunit, ...
                'description', spatial_description, ...
                'comments', spatial_comments);
    %% add TimeSeries objects to PupilTracking and EyeTracking
    % module
    pupil_tracking = types.core.PupilTracking('TimeSeries', pupil);
    eye_tracking = types.core.EyeTracking('SpatialSeries', eye_xy);
end
