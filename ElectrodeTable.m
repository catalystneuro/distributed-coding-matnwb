% Function to create Electrode table with neural data
function nwb_file = ElectrodeTable(nwb_file, ...
                                    probe_descriptions, insertion_df, ...
                                    channel_site, channel_brain,...
                                    channel_probes, channel_sitepos, ...
                                    device_desc, probe_elec_desc, ...
                                    probe_location)

    arguments
        nwb_file {mustBeA(nwb_file, "NwbFile")}
        probe_descriptions (1, :) string
        insertion_df (1, :) string
        channel_site (1, :) string
        channel_brain (1, :) string
        channel_probes (1, :) string
        channel_sitepos (1, :) string
        device_desc char = 'No description'
        probe_elec_desc char = 'No description'
        probe_location char = 'Unknown'
    end
    probe_descriptions = tdfread(probe_descriptions, '\t');
    for p = 1:size(probe_descriptions.description, 1)
        device_name = num2str(p);
        probe_device = types.core.Device('description', device_desc);
        probe_elec_grp = types.core.ElectrodeGroup(...
                                'description', probe_elec_desc, ...
                                'device', probe_device, ...
                                'location', probe_location);
        group_name = ['Probe', num2str(p-1)];
        nwb_file.general_extracellular_ephys.set(group_name, probe_elec_grp);
        nwb_file.general_devices.set(device_name, probe_device);
    end

    % add channel information to electrode table
    insertion_df = tdfread(insertion_df, '\t');
    insertion_df.group_name = (0:length(insertion_df.entry_point_rl)-1)';
    channel_site = readNPY(channel_site);
    channel_brain = tdfread(channel_brain, '\t');
    channel_probes = readNPY(channel_probes);
    channel_probes = ceil(channel_probes(:));

    channel_table = struct('group_name', channel_probes);
    channel_table = join(struct2table(channel_table), ...
                         struct2table(insertion_df), ...
                         'Keys', 'group_name');

    entry_point_rl = channel_table.entry_point_rl;
    entry_point_ap = channel_table.entry_point_ap;
    axial_angle = channel_table.axial_angle;
    vertical_angle = channel_table.vertical_angle;
    horizontal_angle = channel_table.horizontal_angle;
    distance_advanced = channel_table.distance_advanced;

    locations = channel_brain.allen_ontology;
    n_rows = length(locations);
    channel_sitepos = readNPY(channel_sitepos);

    columns = {'x', 'y', 'z', 'imp', 'location', 'filtering', ...
               'site_id', 'site_position', 'ccf_ap', 'ccf_dv', 'ccf_lr', ...
               'entry_point_rl', 'entry_point_ap', 'vertical_angle', ...
               'horizontal_angle', 'axial_angle', 'distance_advanced', 'electrode_group'};

    x = nan(n_rows, 1);
    y = nan(n_rows, 1);
    z = nan(n_rows, 1);
    imp = nan(n_rows, 1);
    filtering = repmat('none',n_rows, 1);

    % prepare electrode group view
    group_view = [];
    for i = 1:n_rows
        ith_group = types.untyped.ObjectView( ...
                ['/general/extracellular_ephys/' 'Probe' num2str(channel_probes(i))]);
        group_view = [group_view, ith_group];
    end

    electrode_tbl = table(x, y, z, imp, locations, filtering, ...
               channel_site, channel_sitepos, channel_brain.ccf_ap, ...
               channel_brain.ccf_dv, channel_brain.ccf_lr, ...
               entry_point_rl, entry_point_ap, vertical_angle, ...
               horizontal_angle, axial_angle, distance_advanced, group_view', ...
               'VariableNames', columns);
    electrode_tbl = util.table2nwb(electrode_tbl, 'all electrodes');
    nwb_file.general_extracellular_ephys_electrodes = electrode_tbl;
end
