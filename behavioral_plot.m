nwb = nwbRead('nicklab~Subjects~Cori~2016-12-17~001~alf.nwb');
markBehavioralEvents(nwb, 'licks', 150, 10);

function markBehavioralEvents(nwb, eventName, start_time, duration)

    arguments
        nwb {mustBeA(nwb, "NwbFile")}
        eventName char = 'lick_times'
        start_time double = 0
        duration double = 10
    end
    
    behavior_module = nwb.processing.get('behavior');
    event = behavior_module.nwbdatainterface.get('BehavioralEvents');
    timestamps = event.timeseries.get('licks').timestamps.load;
    x_ticks = timestamps(timestamps >= start_time & ...
                         timestamps <= start_time + duration);
    plot(x_ticks, ones(length(x_ticks), 1), 'x', ...
         'DisplayName', 'lick times', ...
         'LineWidth', 1.2)
    ylim([0, 2]);
    xlim([start_time start_time+duration]);
    set(gca,'YTickLabel',[]);
    xlabel('time (s)');
    title('Lick time raster');
    legend
end