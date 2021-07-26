% Iteratively call each session in meta table and convert to NWB format
files = dir('allData');
total_files = length(files);

% Create a sample meta data with sessions information
subjects = {'Cori', 'Muller', 'Richards'}';
dates = {'2016-12-14', '2017-01-07', '2017-11-02'}';
session_ids = {'001', '001', '001'}';
meta_table = table(subjects, dates, session_ids);

% loop over iterations
for sess = 1:size(meta_table, 1)
    found = 0; % flag to check the particular session files are available
    for f = 1:total_files
        % get the file name
        f_name = convertCharsToStrings(files(f).name);
        if(strlength(f_name) > 10) % filter out data files
            fields = strsplit(f_name, '~'); % split the name to get fields
            subject = fields(3);
            date = fields(4);
            session_id = fields(5);
            identifier = fields(7);
            % if file fields match with req. session details
            if((subject == meta_table.subjects(sess) && ...
               date == meta_table.dates(sess) && ...
               session_id == meta_table.session_ids(sess)) && ~found)
                 % start converting session data
                 % initialize nwb file object
                 nwb_file = initialize_nwb_object(date, session_id);
                 nwb_file = populate(nwb_file, fields);
                 found = 1;
            end
        end
    end
    msg = sprintf('Processed successfully subject id: %s date: %s session id: %s', ...
                  string(meta_table.subjects(sess)), ...
                  string(meta_table.dates(sess)), ...
                  string(meta_table.session_ids(sess)));
    disp(msg);
end

function f_name = proper_filename(fields, identifier)
    f_name = strcat(strjoin(fields(1:6)), identifier);
    f_name = replace(f_name, ' ', '~');
    f_name = strcat('allData/', f_name);
end

function nwb_file = populate(nwb_file, fields)
    % create processing module
     behavior_mod = types.core.ProcessingModule('description', 'behavior module');
     % Eye
     f_eye_timestamps = proper_filename(fields(1:6), '~eye.timestamps.npy');
     f_eye_area = proper_filename(fields(1:6), '~eye.area.npy');
     f_eye_xy_pos = proper_filename(fields(1:6), '~eye.xyPos.npy');
     ts_data_unit = 'arb. unit';
     ts_description = {'Features extracted from the '
                         'video of the right eye.'};
     ts_comments = {'The area of the pupil extracted '
         'with DeepLabCut. Note that '
         'it is relatively very small during the discrimination task '
         'and during the passive replay because the three screens are '
         'medium-grey at this time and black elsewhere - so the much '
         'brighter overall luminance levels lead to relatively '
         'constricted pupils.'};
     xy_data_unit = ts_data_unit;
     xy_description = {'Features extracted from the video '
                        'of the right eye.'};
     xy_comments = {'The 2D position of the center of the pupil '
                     'in the video frame. This is not registered '
                     'to degrees visual angle, but '
                     'could be used to detect saccades or '
                     'other changes in eye position.'};
     behavior_mod = Eye(behavior_mod, f_eye_timestamps, f_eye_area, ...
                        f_eye_xy_pos, ts_data_unit, ts_description, ts_comments, ...
                        xy_data_unit, xy_description, xy_comments);
     nwb_file.processing.set('behavior', behavior_mod);
end

function nwb_file = initialize_nwb_object(date, session_id)
    % intialize nwb object
    % add subject information
    subject = types.core.Subject('age', 'P77D', ...
                   'genotype', 'tetO-G6s x CaMK-tTA', ...
                   'sex', 'F', ...
                   'species', 'Mus musculus', ...
                   'description', 'strain: C57Bl6/J');
    date = strsplit(string(date), '-');
    % create nwb file
    nwb_file = NwbFile(...
        'session_description', {'Neuropixels recording during visual '
                                'discrimination in awake mice.'}, ...
        'general_session_id', convertStringsToChars(session_id), ...
        'session_start_time', datetime(str2num(date(1)), str2num(date(2)), ...
                                       str2num(date(3)), 12, 0, 0), ...
        'identifier', 'Cori_2016-12-14', ...
        'general_institution', 'University College London', ...
        'general_lab', 'The Carandini & Harris Lab', ...
        'general_subject', subject, ...
        'general_experimenter', 'Nick Steinmetz', ...
        'general_experiment_description', {'Large-scale Neuropixels recordings'
                                           'across brain regions of mice '
                                           'during a head-fixed visual '
                                           'discrimination task. '}, ...
        'general_related_publications', 'DOI 10.1038/s41586-019-1787-x', ...
        'general_keywords', ['Neural coding', 'Neuropixels', 'mouse', ...
                            'brain-wide', 'vision', 'visual discrimination', ...
                            'electrophysiology']);
end
