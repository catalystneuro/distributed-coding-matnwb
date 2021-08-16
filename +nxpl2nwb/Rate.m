function rate = Rate(timestamps)
    %% calculate rate
    arguments 
        timestamps double
    end
    if(size(timestamps, 1) == 1)
        % if only column is there pad 2:total time as another column
        timestamps0 = zeros(2, length(timestamps));
        timestamps0(1, 2:length(timestamps)) = timestamps(1, 2:length(timestamps));
        timestamps = timestamps0;
    end
    rate = (timestamps(2, 2) - timestamps(1, 2)) / (timestamps(2, 1));
end
