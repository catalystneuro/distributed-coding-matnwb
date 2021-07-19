files = dir('allData');
total_files = length(files);

subjects = {'Cori', 'Muller', 'Richards'}';
dates = {'2016-12-14', '2017-01-07', '2017-11-02'}';
session_ids = {'001', '001', '001'}';
meta_table = table(subjects, dates, session_ids);

for sess = 1:size(meta_table, 1)
    count = 0;
    for f = 1:total_files
        f_name = convertCharsToStrings(files(f).name);
        if(strlength(f_name) > 10)
            fields = strsplit(f_name, '~');
            subject = fields(3);
            date = fields(4);
            session_id = fields(5);
            identifier = fields(7);
            if(subject == meta_table.subjects(sess) && ...
               date == meta_table.dates(sess) && ...
               session_id == meta_table.session_ids(sess))   
                 nwb_file = initialize_nwb_object(date, session_id);
                 nwb_file = populate(nwb_file, fields);
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
     nwb_file.processing.set('behavior', behavior_mod);
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
     % Face
     f_face_motion_energy = proper_filename(fields(1:6), '~face.motionEnergy.npy');
     f_face_timestamps = proper_filename(fields(1:6),'~face.timestamps.npy');
     data_unit = 'arb. unit';
     description = {'Features extracted from the video of the '
                        'frontal aspect of the subject, including the '
                        'subject face and forearms.'};
     comments = {'The integrated motion energy across the whole frame'
                 ', i.e. sum( (thisFrame-lastFrame)^2 ). '
                 'Some smoothing is applied before this operation.'};
     behavior_mod = Face(behavior_mod, f_face_motion_energy, f_face_timestamps, ...
                             data_unit, description, comments);
     % Lick piezo
     f_lp_raw = proper_filename(fields(1:6), '~lickPiezo.raw.npy');
     f_lp_ts = proper_filename(fields(1:6), '~lickPiezo.timestamps.npy');
     data_unit = 'V';
     description = {'Voltage values from a thin-film piezo connected to the '
                   'lick spout, so that values are proportional to deflection '
                   'of the spout and licks can be detected as peaks of the signal.'};
     lp_timeseries = LickPiezo(f_lp_raw, f_lp_ts, data_unit, description);
     nwb_file.acquisition.set('LickPiezo', lp_timeseries);
     
     % Lick times
     f_lk_ts = proper_filename(fields(1:6), '~licks.times.npy');
     data_unit = 'Unknown';
     description = {'Extracted times of licks, '
                    'from the lickPiezo signal.'};
     behavior_mod = LickTimes(behavior_mod, f_lk_ts, data_unit, description);
     
     % spontaneous intervals
     f_spot_int = proper_filename(fields(1:6), '~spontaneous.intervals.npy');
     spont_ti = Spontaneous(f_spot_int);
     nwb_file.intervals.set('spontaneous', spont_ti);
     
     %Wheel times
     f_whl_pos = proper_filename(fields(1:6), '~wheel.position.npy'); 
     f_whl_ts = proper_filename(fields(1:6), '~wheel.timestamps.npy'); 
     data_unit = 'mm';
     data_conversion = 0.135;
     description = {'The position reading of the rotary encoder attached to '
                    'the rubber wheel that the mouse pushes left and right '
                    'with his forelimbs.'};
     comments = {'The wheel has radius 31 mm and 1440 ticks per revolution, '
                 'so multiply by 2*pi*r/tpr=0.135 to convert to millimeters. '
                 'Positive velocity (increasing numbers) correspond to clockwise '
                 'turns (if looking at the wheel from behind the mouse), i.e. '
                 'turns that are in the correct direction for stimuli presented '
                 'to the left. Likewise negative velocity corresponds to right choices.'};
     wheel_ts = Wheel(f_whl_pos, f_whl_ts, data_unit, data_conversion, ...
                      description, comments);
     nwb_file.acquisition.set('WheelTimes', wheel_ts);
     
     % Wheel moves
     f_whl_moves_type = proper_filename(fields(1:6), '~wheelMoves.type.npy');
     f_whl_moves_int = proper_filename(fields(1:6), '~wheelMoves.intervals.npy');
     description = {'Detected wheel movements.'};
     comments = {'0 for flinches or otherwise unclassified movements, '
                 '1 for left/clockwise turns, 2 for right/counter-clockwise '
                 'turns (where again "left" means "would be the correct '
                 'direction for a stimulus presented on the left). A detected '
                 'movement is counted as left or right only if it was '
                 'sufficient amplitude that it would have registered a correct '
                 'response (and possibly did), within a minimum amount of time '
                 'from the start of the movement. Movements failing those '
                 'criteria are flinch/unclassified type.'};
     behavior_mod = WheelMoves(behavior_mod, f_whl_moves_type, f_whl_moves_int, ...
                               description, comments);
     
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

