% Function to create Electrode table with neural data
function [nwb_file, group_view] = ElectrodeTable(nwb_file, file_prefix, ...
                                    probe_location, device_description, ...
                                    probe_electrode_description)

    arguments
        nwb_file {mustBeA(nwb_file, "NwbFile")}
        file_prefix (1, :) string = ''
        probe_location char = 'Unknown'
        device_description = 'device description'
        probe_electrode_description = 'probe description'
    end

    fname_probe_descriptions = strcat(file_prefix, 'probes.description.tsv');
    fname_insertion_data = strcat(file_prefix, 'probes.insertion.tsv');
    fname_channel_site = strcat(file_prefix, 'channels.site.npy');
    fname_channel_brain = strcat(file_prefix, 'channels.brainLocation.tsv');
    fname_channel_probes = strcat(file_prefix, 'channels.probe.npy');
    fname_channel_sitepos = strcat(file_prefix, 'channels.sitePositions.npy');

    probe_descriptions = tdfread(fname_probe_descriptions, '\t');
    for p = 1:size(probe_descriptions.description, 1)
        device_name = num2str(p);
        probe_device = types.core.Device('description', device_description);
        device_link = types.untyped.SoftLink(['/general/devices/' device_name]);
        probe_electrode_grp = types.core.ElectrodeGroup(...
                                'description', probe_electrode_description, ...
                                'device', device_link, ...
                                'location', probe_location);
        group_name = ['Probe', num2str(p-1)];
        nwb_file.general_extracellular_ephys.set(group_name, ...
                                                 probe_electrode_grp);
        nwb_file.general_devices.set(device_name, probe_device);
    end

    % add channel information to electrode table
    insertion_data = tdfread(fname_insertion_data, '\t');
    insertion_data.group_name = (0:length(insertion_data.entry_point_rl)-1)';
    channel_site = readNPY(fname_channel_site);
    channel_brain = tdfread(fname_channel_brain, '\t');
    channel_probes = readNPY(fname_channel_probes);
    channel_probes = uint8(channel_probes(:));

    channel_table = struct('group_name', channel_probes);
    channel_table = join(struct2table(channel_table), ...
                         struct2table(insertion_data), ...
                         'Keys', 'group_name');

    entry_point_rl = channel_table.entry_point_rl;
    entry_point_ap = channel_table.entry_point_ap;
    axial_angle = channel_table.axial_angle;
    vertical_angle = channel_table.vertical_angle;
    horizontal_angle = channel_table.horizontal_angle;
    distance_advanced = channel_table.distance_advanced;
    locations = channel_brain.allen_ontology;
    n_rows = length(locations);
    channel_sitepos = readNPY(fname_channel_sitepos);
    rel_x = channel_sitepos(:, 1);
    rel_y = channel_sitepos(:, 2);

    columns = {'x', 'y', 'z', 'imp', 'location', 'filtering', ...
               'site_id', 'rel_x', 'rel_y', 'ccf_ap', 'ccf_dv', 'ccf_lr', ...
               'entry_point_rl', 'entry_point_ap', 'vertical_angle', ...
               'horizontal_angle', 'axial_angle', 'distance_advanced', ...
               'electrode_group'};

    x = nan(n_rows, 1);
    y = nan(n_rows, 1);
    z = nan(n_rows, 1);
    imp = nan(n_rows, 1);
    filtering = repmat({'none'},n_rows, 1);

    % prepare electrode group view
    group_view = [];
    for i = 1:n_rows
        ith_group = types.untyped.ObjectView( ...
      ['/general/extracellular_ephys/' 'Probe' num2str(channel_probes(i))]);
      group_view = [group_view, ith_group];
    end

    electrode_table = table(x, y, z, imp, cellstr(locations), filtering, ...
               channel_site, rel_x, rel_y, channel_brain.ccf_ap, ...
               channel_brain.ccf_dv, channel_brain.ccf_lr, ...
               entry_point_rl, entry_point_ap, vertical_angle, ...
               horizontal_angle, axial_angle, distance_advanced, ...
               group_view', ...
               'VariableNames', columns);

    electrode_table = util.table2nwb(electrode_table, 'Electrode table');
    nwb_file.general_extracellular_ephys_electrodes = electrode_table;
end
