function rate = Rate(timestamps)
    %% calculate rate
    arguments 
        timestamps (2, :) double
    end
    rate = (timestamps(2, 2) - timestamps(1, 2)) / (timestamps(2, 1));
end
