% function to add receptive field mapping task to nwb_file.stimulus
function sp_noise = SparseNoise(sp_noise_pos, sp_noise_t, data_unit, ...
                                description, comments)
    arguments
        sp_noise_pos (1, :) string
        sp_noise_t (1, :) string
        data_unit char = 'Unknown'
        description char = 'No description'
        comments char = 'No comments'
    end
    sp_noise_pos = readNPY(sp_noise_pos);
    sp_noise_t = readNPY(sp_noise_t);

    sp_noise = types.core.TimeSeries(...
                'timestamps', sp_noise_t', ...
                'data', sp_noise_pos, ...
                'data_unit', data_unit, ...
                'description', description, ...
                'comments', comments);
end
