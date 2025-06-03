function [distance_matrix] = compute_pca_similarity(sim,params)

% Get ROI matrices
FOV = false(params.fovSize, params.fovSize, params.nRois, params.nDays);
for d = 1:params.nDays
    for r = 1:params.nRois
        FOV(:,:,r,d) = sim(d,r).mask;
    end
end

% Initialize results vector
distance_matrix = nan(params.nDays,params.nDays);

for d = 1:params.nDays
    for dd = d:params.nDays
        
        roi_mat1 = reshape(FOV(:,:,:,d),[],params.nRois)'; roi_mat2 = reshape(FOV(:,:,:,dd),[],params.nRois)';
        
        % Add random noise for PCA on same day
        if dd == d
            roi_mat2 = roi_mat2 + 1e-2 * randn(size(roi_mat2));
        end
        
        roi_for_pca = double([roi_mat1; roi_mat2]); % combine ROIs from both days
        roi_for_pca = roi_for_pca - mean(roi_for_pca, 1); % mean-centering for each ROI
        
        % Run PCA
        [~, ~, ~, ~, explained] = pca(roi_for_pca);
        cum_exp = cumsum(explained);
        num_components_95 = find(cum_exp >= 95, 1);
        similarity_score = num_components_95 / size(roi_for_pca,1);
        distance_matrix(dd,d) = similarity_score;
    end
end
end