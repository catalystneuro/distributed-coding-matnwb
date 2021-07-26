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
                 %nwbExport(nwb_file, 'single_session.nwb');
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
     behavior_mod = types.core.ProcessingModule(...
                                    'description', 'behavior module');
     %% Converting Eye data
     f_eye_timestamps = proper_filename(fields(1:6), ...
                                            '~eye.timestamps.npy');
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

     %% Convert Face energy data
     f_face_motion_energy = proper_filename(fields(1:6), ...
                                    '~face.motionEnergy.npy');
     f_face_timestamps = proper_filename(fields(1:6), ...
                                    '~face.timestamps.npy');
     data_unit = 'arb. unit';
     description = {'Features extracted from the video of the '
                    'frontal aspect of the subject, including the '
                    'subject face and forearms.'};
     comments = {'The integrated motion energy across the whole frame'
                 ', i.e. sum( (thisFrame-lastFrame)^2 ). '
                 'Some smoothing is applied before this operation.'};
     behavior_mod = Face(behavior_mod, ...
                         f_face_motion_energy, f_face_timestamps, ...
                         data_unit, description, comments);

     %% Convert Lick piezo data and add as NWB.acquisition
     f_lp_raw = proper_filename(fields(1:6), '~lickPiezo.raw.npy');
     f_lp_ts = proper_filename(fields(1:6), '~lickPiezo.timestamps.npy');
     data_unit = 'V';
     description = {'Voltage values from a thin-film piezo '
                    'connected to the lick spout, so that values '
                    'are proportional to deflection '
                    'of the spout and licks can be detected '
                    'as peaks of the signal.'};
     lp_timeseries = LickPiezo(f_lp_raw, f_lp_ts, data_unit, description);
     nwb_file.acquisition.set('LickPiezo', lp_timeseries);

     %% Convert Trials data and create NWB TrialTable
     f_included = proper_filename(fields(1:6), ...
                            '~trials.included.npy');
     f_fb_type = proper_filename(fields(1:6), ...
                            '~trials.feedbackType.npy');
     f_fb_time = proper_filename(fields(1:6), ...
                            '~trials.feedback_times.npy');
     f_go_cue = proper_filename(fields(1:6), ...
                            '~trials.goCue_times.npy');
     f_trial_intervals = proper_filename(fields(1:6), ...
                            '~trials.intervals.npy');
     f_rep_num = proper_filename(fields(1:6), ...
                            '~trials.repNum.npy');
     f_response_choice = proper_filename(fields(1:6), ...
                            '~trials.response_choice.npy');
     f_response_times = proper_filename(fields(1:6), ...
                            '~trials.response_times.npy');
     f_visual_left = proper_filename(fields(1:6), ...
                            '~trials.visualStim_contrastLeft.npy');
     f_visual_right = proper_filename(fields(1:6), ...
                            '~trials.visualStim_contrastRight.npy');
     f_visual_times = proper_filename(fields(1:6), ...
                            '~trials.visualStim_times.npy');

     description = 'trial table for behavioral trials';
     included_desc = {'Importantly, while this '
                    'variable gives inclusion criteria according '
                    'to the definition of disengagement '
                    '(see manuscript Methods), it does '
                    'not give inclusion criteria based on the '
                    'time of response, as used '
                    'for most analyses in the paper.'};
     go_cue_desc = {'The goCue is referred to as the '
                    'auditory tone cue in the manuscript.'};
     visual_stimulus_time_desc = {'Times are relative to the same time'
                              'base as every other time in the '
                              'dataset, not to the start of the trial'};
     visual_stimulus_left_desc = {'Proportion contrast. A value of 0.5 '
                               'means 50% contrast. 0 is a blank '
                               'screen: no change to any pixel values on '
                               'that side (completely undetectable).'};
     visual_stimulus_right_desc = {'Times are relative to the same '
                          'time base as every other time in the dataset, '
                          'not to the start of the trial.'};
     response_time_desc = {'Enumerated type. The response registered '
                    'at the end of the trial, '
                    'which determines the feedback according to the '
                    'contrast condition. Note that in a small percentage '
                    'of cases (~4%, see manuscript Methods) '
                    'the initial wheel turn was in the opposite direction.'
                    '-1 for Right choice (i.e. correct when stimuli are '
                    'on the right); +1 for left choice; '
                    '0 for Nogo choice.'};
     response_choice_desc = {'Enumerated type. The response '
                        'registered at the end of the trial, '
                        'which determines the feedback '
                        'according to the contrast condition. '
                        'Note that in a small percentage of cases '
                        '(~4%, see manuscript Methods) '
                        'the initial wheel turn was in the opposite '
                        'direction. -1 for Right '
                        'choice (i.e. correct when stimuli are on the '
                        'right); +1 for left '
                        'choice; 0 for Nogo choice.'};
      feedback_time_desc = {'Times are relative to the same time '
                       'base as every other time in the dataset, '
                       'not to the start of the trial.'};
      feedback_type_desc = {'Enumerated type. -1 for negative '
                       'feedback (white noise burst); +1 for '
                       'positive feedback (water reward delivery).'};
      rep_num_desc ={'Trials are repeated if they are "easy" '
            'trials (high contrast stimuli with large difference '
            'between the two sides, or the blank screen condition) and '
            'this keeps track of how many times the current '
            'trials condition has been repeated.'};

     trials = TrialTable(f_included, f_fb_type, f_fb_time, f_go_cue, ...
            f_trial_intervals, f_rep_num, f_response_choice, ...
            f_response_times, f_visual_left, f_visual_right, ...
            f_visual_times, description, ...
            included_desc, go_cue_desc, visual_stimulus_time_desc, ...
            visual_stimulus_left_desc, visual_stimulus_right_desc, ...
            response_time_desc, response_choice_desc, ...
            feedback_time_desc, feedback_type_desc, ...
            rep_num_desc);
     nwb_file.intervals_trials = trials;

     %%
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
