% Convert Face energy behavioral data
function face_energy = Face(file_prefix, dataunit, description, comments)
    arguments
        file_prefix (1, :) string = ''
        dataunit char = 'Unknown'
        description char = 'Features extracted from frontal part of the subject'
        comments char = 'No comments'
    end
    %% Read data files and create TimeSeries object
    fname_face_motionenergy = strcat(file_prefix, 'face.motionEnergy.npy');
    fname_face_timestamps = strcat(file_prefix, 'face.timestamps.npy');

    face_motionenergy = readNPY(fname_face_motionenergy);
    face_timestamps = readNPY(fname_face_timestamps);

    face_rate = nxpl2nwb.Rate(face_timestamps);
    face_energy = types.core.TimeSeries(...
        'data', face_motionenergy', ...
        'data_unit', dataunit, ...
        'starting_time', face_timestamps(1, 2), ...
        'starting_time_rate', face_rate, ...
        'description', description, ...
        'comments', comments);

end
