% Iteratively call each session in meta table and convert to NWB format
files = dir('allData');
total_files = length(files);

% Create a sample meta data with sessions information
subjects = {'Cori'}';
dates = {'2016-12-14'}';
session_ids = {'001'}';
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
                 nwbExport(nwb_file, 'chakpak.nwb');
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
    % create file prefix string and processing module
     file_prefix = strcat('allData/', strjoin(fields(1:6)), '~');
     file_prefix = replace(file_prefix, ' ', '~');

     behavior_module = types.core.ProcessingModule(...
                                    'description', 'behavior module');
     %% Converting Eye data
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
     [pupil_tracking, eye_tracking] = nxpl2nwb.Eye(file_prefix, ...
                       ts_data_unit, ts_description, ts_comments, ...
                       xy_data_unit, xy_description, xy_comments);
     behavior_module.nwbdatainterface.set('PupilTracking', pupil_tracking);
     behavior_module.nwbdatainterface.set('EyeTracking', eye_tracking);
     nwb_file.processing.set('behavior', behavior_module);

     %% Convert Face energy data
     dataunit = 'arb. unit';
     description = {'Features extracted from the video of the '
                    'frontal aspect of the subject, including the '
                    'subject face and forearms.'};
     comments = {'The integrated motion energy across the whole frame'
                 ', i.e. sum( (thisFrame-lastFrame)^2 ). '
                 'Some smoothing is applied before this operation.'};
     face_energy = nxpl2nwb.Face(file_prefix, dataunit, ...
                                    description, comments);
     behavior_module.nwbdatainterface.set(...
                    'BehavioralTimeSeries', face_energy);

     %% Convert Lick piezo data and add as NWB.acquisition
     data_unit = 'V';
     description = {'Voltage values from a thin-film piezo '
                    'connected to the lick spout, so that values '
                    'are proportional to deflection '
                    'of the spout and licks can be detected '
                    'as peaks of the signal.'};
     lp_timeseries = nxpl2nwb.LickPiezo(file_prefix, data_unit, description);
     nwb_file.acquisition.set('LickPiezo', lp_timeseries);

     %% Convert Lick times data
     data_unit = 'Unknown';
     description = {'Extracted times of licks, '
                    'from the lickPiezo signal.'};
     lick_events = nxpl2nwb.LickTimes(file_prefix, data_unit, ...
                              description);
     behavior_module.nwbdatainterface.set(...
                    'BehavioralEvents', lick_events);

     %% Convert spontaneous intervals
     description = {'Intervals of sufficient duration when nothing '
                    'else is going on (no task or stimulus presentation'};
     spontaneous_timeintervals = nxpl2nwb.Spontaneous(file_prefix, ...
                                                      description);
     nwb_file.intervals.set('spontaneous', spontaneous_timeintervals);

     %% Wheel times
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
     wheel_timeseries = nxpl2nwb.Wheel(file_prefix, data_unit, data_conversion, ...
                               description, comments);
     nwb_file.acquisition.set('WheelTimes', wheel_timeseries);

     %% Wheel moves
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
     wheel_moves_behavior = nxpl2nwb.WheelMoves(file_prefix, ...
                                        description, comments);
     behavior_module.nwbdatainterface.set(...
                    'BehavioralEpochs', wheel_moves_behavior);

     %% Sparse Noise
     data_unit = 'degrees visual angle';
     description = {'White squares shown on the screen with randomized '
                    'positions and timing - see manuscript Methods.'};
     comments = {'The altitude (first column) and azimuth (second column) '
                 'of the square.'};
     sparsenoise_timeseries = nxpl2nwb.SparseNoise(file_prefix, ...
                                        data_unit, description, comments);
     nwb_file.stimulus_presentation.set(...
         'receptive_field_mapping_sparse_noise', sparsenoise_timeseries);
     %% Convert Trials data and create NWB TrialTable
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

     trials = nxpl2nwb.TrialTable(file_prefix, description, ...
            included_desc, go_cue_desc, visual_stimulus_time_desc, ...
            visual_stimulus_left_desc, visual_stimulus_right_desc, ...
            response_time_desc, response_choice_desc, ...
            feedback_time_desc, feedback_type_desc, ...
            rep_num_desc);
     nwb_file.intervals_trials = trials;
     return;
     %% Convert Passive stimulus data
     % passive beeps
     pass_beeps = proper_filename(fields(1:6), '~passiveBeeps.times.npy');
     pb_data_unit = 'Unknown';
     pb_description = {'Auditory tones of the same frequency as '
                       'the auditory tone cue in the task'};
     % passive valve clicks
     pass_clicks = proper_filename(fields(1:6), '~passiveValveClick.times.npy');
     pc_data_unit = 'Unknown';
     pc_description = {'Opening of the reward valve, but with a clamp in place '
             'such that no water flows. Therefore the auditory sound of '
             'the valve is heard, but no water reward is obtained.'};

     % passive visual times
     pass_vis = proper_filename(fields(1:6), '~passiveVisual.times.npy');
     pass_vis_left = proper_filename(fields(1:6), '~passiveVisual.contrastLeft.npy');
     pass_vis_right = proper_filename(fields(1:6), '~passiveVisual.contrastRight.npy');
     pvl_data_unit = 'proportion contrast';
     pvl_description = {'Gratings of the same size, spatial freq, position, etc '
                       'as during the discrimination task.'};
     pvr_data_unit = 'proportion contrast';
     pvr_description = {'Gratings of the same size, spatial freq, position, etc '
                       'as during the discrimination task.'};
     % passive valve clicks
     pass_noise = proper_filename(fields(1:6), '~passiveWhiteNoise.times.npy');
     pvc_data_unit = 'Unknown';
     pvc_description = {'The sound that accompanies an incorrect response '
                        ' during the discrimination task.'};
     [beep_ts, click_ts, pass_l, pass_r, pass_white] = nxpl2nwb.PassiveStim(...
              pass_beeps, pass_clicks, pass_vis, pass_vis_left, ...
                  pass_vis_right, pass_noise, ...
                  pb_data_unit, pb_description, ...
                  pc_data_unit, pc_description, ...
                  pvl_data_unit, pvl_description, ...
                  pvr_data_unit, pvr_description, ...
                  pvc_data_unit, pvc_description);
     nwb_file.stimulus_presentation.set('passive_beeps', beep_ts);
     nwb_file.stimulus_presentation.set('passive_click_times', click_ts);
     nwb_file.stimulus_presentation.set('passive_left_contrast', pass_l);
     nwb_file.stimulus_presentation.set('passive_right_contrast', pass_r);
     nwb_file.stimulus_presentation.set('passive_white_noise', pass_white);

     %% Create Electrode table to add neural data
     probe_descriptions = proper_filename(fields(1:6), '~probes.description.tsv');
     device_desc = 'Probe device';
     probe_elec_desc = 'Neuropixels Phase3A opt3';
     probe_location = 'Unknown';
     insertion_df = proper_filename(fields(1:6), '~probes.insertion.tsv');
     channel_site = proper_filename(fields(1:6), '~channels.site.npy');
     channel_brain = proper_filename(fields(1:6), '~channels.brainLocation.tsv');
     channel_probes = proper_filename(fields(1:6), '~channels.probe.npy');
     channel_sitepos = proper_filename(fields(1:6), '~channels.sitePositions.npy');

     [nwb_file, group_view] = nxpl2nwb.ElectrodeTable(nwb_file, ...
                            probe_descriptions, insertion_df, ...
                            channel_site, channel_brain,...
                            channel_probes, channel_sitepos, ...
                            device_desc, probe_elec_desc, ...
                            probe_location);
     %% Create Units table for clusters and spikes data
     cluster_probe = proper_filename(fields(1:6), '~clusters.probes.npy');
     cluster_channel = proper_filename(fields(1:6), '~clusters.peakChannel.npy');
     cluster_depths = proper_filename(fields(1:6), '~clusters.depths.npy');
     phy_annotations = proper_filename(fields(1:6), '~clusters._phy_annotation.npy');
     waveform_chans = proper_filename(fields(1:6), '~clusters.templateWaveformChans.npy');
     waveform = proper_filename(fields(1:6), '~clusters.templateWaveforms.npy');
     waveform_duration = proper_filename(fields(1:6), '~clusters.waveformDuration.npy');
     spike_to_clusters = proper_filename(fields(1:6), '~spikes.clusters.npy');
     spike_times = proper_filename(fields(1:6), '~spikes.times.npy');
     spike_amps = proper_filename(fields(1:6), '~spikes.amps.npy');
     spike_depths = proper_filename(fields(1:6), '~spikes.depths.npy');
     description = 'Units table';
     electrode_group_desc = 'Electrode group';
     electrodes_desc = 'Electrodes';
     waveform_mean_desc = 'Waveform mean';
     peakchannel_desc = {'The channel number of the location of '
                        'the peak of the cluster waveform.'};
     waveformduration_desc = {'The trough-to-peak duration of '
                              'the waveform on the peak channel'};
     phyannotations_desc = {'0 = noise (these are already excluded and '
                'dont appear in this dataset '
                'at all); 1 = MUA (i.e. presumed to contain '
                'spikes from multiple neurons; '
                'these are not analyzed in any analyses in the paper)'
                '; 2 = Good (manually '
                'labeled); 3 = Unsorted. In this '
                'dataset Good was applied in a few but '
                'not all datasets to included neurons, '
                'so in general the neurons with '
                '_phy_annotation>=2 are the ones that should be included.'};
     clusterdepths_desc = {'The position of the center of mass of the template of the cluster, '
                    'relative to the probe. The deepest channel on the probe is depth=0, '
                    'and the most superficial is depth=3820. Units: µm'};
     samplingrate_desc = {'Sampling rate in Hz'};
     spikeamps_desc = {'The peak-to-trough amplitude, '
                    'obtained from the template and '
                    'template-scaling amplitude returned by Kilosort '
                    '(not from the raw data).'};
     spikedepths_desc = {'The position of the center of mass '
                        'of the spike on the probe, '
                        'determined from the principal component features '
                        'returned by Kilosort. '
                        'The deepest channel on the probe is depth=0, '
                        'and the most superficial is depth=3820.'};
     nwb_file = nxpl2nwb.ClustersSpikes(nwb_file, group_view, ...
                    cluster_probe, cluster_channel, cluster_depths, ...
                    phy_annotations, waveform_chans, waveform, ...
                    waveform_duration, spike_to_clusters, ...
                    spike_times, spike_amps, spike_depths, ...
                    description, electrode_group_desc, electrodes_desc, ...
                    waveform_mean_desc, peakchannel_desc, waveformduration_desc, ...
                    phyannotations_desc, clusterdepths_desc, ...
                    samplingrate_desc, spikeamps_desc, spikedepths_desc);
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
