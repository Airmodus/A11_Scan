function data_ave = average_data(time, data, time_ave, method)

// Calculate data to new time vector.

// data_ave = average_data(time, data, time_ave, method)
//
// time      = original time vector
// data      = original data
// time_ave  = time vector, middle points of the averaging window
// method    = 'mean' or 'median'
//
// data_ave  = averaged data


data_ave = [];
if size(time_ave,1) < 2 then
    data_ave = nanmean(data)
else

time_step = time_ave(2)-time_ave(1);

for k=1:length(time_ave)
    findex = find(time_ave(k)-time_step/2 <= time&...
                   time < time_ave(k)+time_step/2);
    if ~isempty(findex)
        if strcmp(method,'mean')
            data_ave = [data_ave; nanmean(data(findex,:),1)];
        elseif strcmp(method,'median')
            data_ave = [data_ave; nanmedian(data(findex,:),1)];
        else
            data_ave = [data_ave; %nan*ones(1,size(data,2))];
        end
    else
        data_ave = [data_ave; %nan*ones(1,size(data,2))];
    end
end
end
endfunction
