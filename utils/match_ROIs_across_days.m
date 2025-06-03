function [matchStats] = match_ROIs_across_days(sim,params)

% Get ROI matrices
FOV = false(params.fovSize, params.fovSize, params.nRois, params.nDays);
for d = 1:params.nDays
    for r = 1:params.nRois
        FOV(:,:,r,d) = sim(d,r).mask;
    end
end

matchStats = struct();

% Match ROIs based on Jaccard index
for d = 1:(params.nDays - 1)
    roi_day1 = FOV(:,:,:,d);
    roi_day2 =  FOV(:,:,:,d+1);
    
    n1 = size(roi_day1, 3);
    n2 = size(roi_day2, 3);
    
    if params.shuffle == 1
        roi_day2 = shuffle_rois_in_fov(roi_day2);
    end
    
    % reshape ROIs
    roi_day1 = reshape(roi_day1,[],n1)';
    roi_day2 = reshape(roi_day2,[],n2)';
    matched_pairs = [];  % store matched [roi_idx_day1, roi_idx_day2]
    
    for i = 1:n1
        roi1 = roi_day1(i,:) > 0;
        max_score = 0;
        best_idx = NaN;
        
        for j = 1:n2
            roi2 = roi_day2(j,:) > 0;
            intersection = sum(roi1 & roi2);
            union = sum(roi1 | roi2);
            jaccard = intersection / union;
            if jaccard > max_score
                max_score = jaccard;
                best_idx = j;
            end
        end
        
        if max_score > params.threshold
            matched_pairs = [matched_pairs; i, best_idx];
        end
    end
    
    % Store results
    matchStats(d).day_pair = [d, d+1];
    matchStats(d).n_day1 = n1;
    matchStats(d).n_day2 = n2;
    matchStats(d).n_matched = size(matched_pairs, 1);
    matchStats(d).percent_matched = size(matched_pairs,1) / n1;
    matchStats(d).matched_indices = matched_pairs;
end

end