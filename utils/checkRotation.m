%% Check rotation values
function [r_sw] = checkRotation(r)
% r = Xn{1}(5,:);
r_0 = r(2:end);
diff = r(1:end-1) - r_0;
r_sw = r;

if abs(range(diff)) > 1
    ma = max(diff);
    maxIndex = find(diff > 0.5*ma);
    mi = min(diff);
    minIndex = find(diff < 0.5*mi);
    
    switch_ids = [maxIndex minIndex];
    switch_ids = sort(switch_ids);
    
    for i=1:2:length(switch_ids)      
        start_id = switch_ids(i) + 1;
        if i<length(switch_ids)
            end_id = switch_ids(i + 1);
        else
            end_id = length(r);
        end
        r_sw(start_id:end_id) = r(start_id:end_id)*-1;
    end
    r_sw = ones(1,length(r));
end

end