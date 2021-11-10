% PSTH Plot Peristimulus time histogram categorized by
% given trial data found in trials table columns
%%
% ARGUMENTS
% nwb   -       Input NWB file
% unit_id -     Unit Id of unit in Units table
% group_by -    name of the data type to group (by default, no grouping)
% before_time - left open range of time interval. Generally, it is negative
%               (by default before_time = -0.5 s)
% after_time -  right open range of time interval and must be greater than
%               before_time (by default after_time = 1.0 s)
% n_bins -      number of histogram bins (by default n_bins = 30)
% psth_plot_option - Plot option to whether plot histogram or smoothed
%                    gaussian plot (by default `histogram`)
%                    Available options are `histogram`, and
%                    `gaussian`
% std -         standard deviation of Gaussian filter
%               (by default std = 0.05)
%%
% EXAMPLE
% nwb_file = nwbRead('example.nwb');
% unit_id = 5;
% before_time = -20;
% after_time = 10;
% group_by = 'visual_stimulus_left_contrast';
% n_bins = 50;
% psth_plot_option = 'gaussian';
% std = 0.03;
% psth(...
%    nwb_file, ...
%    unit_id = 5, ...
%    group_by = 'visual_stimulus_left_contrast', ...
%    before_time = -20, ...
%    after_time = 10, ...
%    n_bins = 50, ...
%    psth_plot_option = 'gaussian', ...
%    std = 0.03);
%
%%
% Note:
% 1. unit for all time arguments (before_time/after_time) should be in seconds
% 2. unique values in group_by variable's data should not be more than 5
%%
function psth(nwb, options)
    arguments
        nwb {mustBeA(nwb, "NwbFile")}
        options.unit_id uint16
        options.group_by char = 'no-condition'
        options.before_time double = -0.5
        options.after_time double = 1.0
        options.n_bins double = 30
        options.psth_plot_option char = 'histogram'
        options.std double = 0.05
    end
    %%
    unit_id = options.unit_id;
    group_by = options.group_by;
    before_time = options.before_time;
    after_time = options.after_time;
    n_bins = options.n_bins;
    psth_plot_option = options.psth_plot_option;
    std = options.std;
    % new figure to detach from gui figure
    f = figure();
    % check valid before time
    if(after_time <= before_time)
        error('after_time must be greater than before_time');
    end
    % warn if before time is non-negative
    if(before_time > 0)
        warning(['before_time is positive,' ...
                 'left offset is after trial start time']);
    end
    % check psth_plot_option argument
    valid_plotOptions = {'histogram', 'gaussian'};
    if(~any(strcmp(psth_plot_option, valid_plotOptions)))
        error(['Invalid `psth_plot_option` value' ...
               'Only `histogram` & `gaussian` are valid']);
    end
    % get spike times of given unit id in open interval
    % (before_time, after_time)
    spike_times = util.read_indexed_column(nwb.units.spike_times_index, ...
                                           nwb.units.spike_times, ...
                                           unit_id);
    % get list of trial start times
    trial_start_times = nwb.intervals_trials.start_time.data.load;
    % get group-by data from Trials table, if no group_by set flag = 1
    no_group_flag = 0;
    groupby_data = 1;
    unique_data = 1; % set unique data as 1 if no group_by variable
    if(strcmp(group_by, 'no-condition'))
        no_group_flag = 1;
    else
        groupby_data = nwb.intervals_trials.vectordata.get(group_by).data.load;
        % check unique data in group_by <= 5
        unique_data = unique(groupby_data);
        if(length(unique_data) > 5)
            error(['no. of unique values in group-by variable' ...
                  'cannot be more than five']);
        end
    end
    num_rows_plot = length(unique_data) + 1;
    pad_width = 2.4 * std;
    psth_data = {};
    % load spike times with pad +- pad_width
    start_offset = before_time - pad_width;
    end_offset = after_time + pad_width;
    for i = 1:length(trial_start_times)
        start_time = trial_start_times(i);
        psth_data{end+1} = spike_times(...
                           spike_times >= start_time + start_offset & ...
                           spike_times <= start_time + end_offset) - ...
                           start_time;
    end
    %% Spike times plot
    color_palette = {'#1f77b4'; '#ff7f0e'; '#2ca02c'; ...
                     '#d62728'; '#9467bd'};
    subplot(num_rows_plot, 1, 1)
    hold on
    counter = 0;
    % cell to collect group-wise spike times
    groupby_spike_times = cell(length(unique_data), 1);
    % change palette if no group by variable
    if(no_group_flag)
        color_palette = {'#47476b'};
    end
    % if no group_by is set, the outer loop run only once
    for u = 1:length(unique_data)
        for i = 1:length(psth_data)
            % check whether the data belongs to particular group-by
            % variable type
            if(no_group_flag || groupby_data(i) == unique_data(u))
                row_data = psth_data{i};
                counter = counter + 1;
                plot(row_data, ones(length(row_data),1) * counter, '.', ...
                     'Color', color_palette{u}, ...
                     'DisplayName', num2str(unique_data(u)));
                groupby_spike_times{u}{end+1} = row_data;
            end
        end
    end
    % chops off padded part
    xlim([before_time after_time]);
    ylim([0 length(trial_start_times)]);
    xline(0, '--'); % mark trial start time
    ylabel('Trials');
    title('Spike times');
    %% PSTH
    % set visbile_mode for histogram according to plot option
    visible_mode = 'on';
    if(strcmp(psth_plot_option, 'gaussian'))
        visible_mode = 'off';
    end
    % number of trials
    num_trials = nwb.intervals_trials.id.data.dims;
    % time points for gaussian curve
    gaussian_xpoints = 1000;
    % plot section
    for u = 1:length(unique_data)
        subplot(num_rows_plot, 1, u+1)
        hold on
        group_spike_times = cell2mat(groupby_spike_times{u});
        valid_indices = find(group_spike_times >= before_time & ...
                             group_spike_times <= after_time);
        hist_spike_times = group_spike_times(valid_indices);
        % add one extra bin for histcounts and bar plot
        h_edges = linspace(before_time, after_time, n_bins+1);
        firing_rate = histcounts(hist_spike_times(:), h_edges, ...
                                 'Normalization', 'countdensity');
        firing_rate = firing_rate / num_trials;
        t_midpoints = h_edges(1:length(h_edges)-1)+(h_edges(2)-h_edges(1))/2;
        bar(t_midpoints, firing_rate, ...
            'DisplayName', num2str(unique_data(u)), ...
            'FaceColor', color_palette{u}, ...
            'BarWidth', 1, ...
            'Visible', visible_mode);
        % apply gaussian filter
        if(~strcmp(psth_plot_option, 'histogram'))
            gauss_edges = linspace(before_time - pad_width, ...
                                   after_time + pad_width, ...
                                   gaussian_xpoints);
            gauss_dt = gauss_edges(2)-gauss_edges(1);
            % histogram to calculate firing rate
            bin_rate = histcounts(group_spike_times, gauss_edges, ...
                                  'Normalization', 'countdensity');
            bin_rate = bin_rate / num_trials;
            % calculate gaussian window
            gauss_window = gaussFilter1D(100, std, gauss_dt);
            % apply convolution
            gaussian_filtered = conv(bin_rate, gauss_window, 'same');
            valid_indices = find(gauss_edges >= before_time & ...
                                 gauss_edges <= after_time);
            plot(gauss_edges(valid_indices), ...
                 gaussian_filtered(valid_indices), ...
                 'linewidth', 2, ...
                 'Color', color_palette{u}, ...
                 'DisplayName', num2str(unique_data(u)));
        end

        % update title according to plot options
        if(~no_group_flag)
            title_msg = [replace(group_by, '_', ' '), ...
                         ' = ', num2str(unique_data(u))];
            title(title_msg);
        end
        xlim([before_time after_time]);
        ylim([0 inf]);
        ylabel('Rate (Hz)');
    end
    % add x label only for last subplot
    xlabel('time (s)');
    title_msg = 'PSTH';
    if(strcmp(psth_plot_option, 'gaussian'))
            title_msg = ['PSTH smoothed with Gaussian '...
                         'filter (\sigma=', num2str(std), ')'];
    end
    if(~no_group_flag)
        title_msg = [title_msg, ' grouped by ', ...
                     replace(group_by, '_', ' ')];
    end
    sgtitle(title_msg);
    hold off;
end
%% Function to create gaussian filter
function h = gaussFilter1D(arr_size, sigma, dt)
    %create regularly spaced array based on size
    x = linspace(dt, arr_size , arr_size*(1/dt));
    %gaussian function
    exp_term = exp(-0.5*((x-mean(x)).^2)/(sigma*sigma));
    h = dt*(1/(sqrt(2*pi)*sigma))*exp_term;
end
