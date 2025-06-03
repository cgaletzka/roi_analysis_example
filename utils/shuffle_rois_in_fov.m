function shuffled_masks = shuffle_rois_in_fov(originalROIs)

[X, Y, nROIs] = size(originalROIs);

mstack = logical(mean(originalROIs,3));
valid_mask_original = ones(X,Y);
coverage_fraction = sum(mstack(:)) / sum(valid_mask_original(:)); % fraction of covered area

coverage_criterion_fulfilled = false;
while ~coverage_criterion_fulfilled
    
    shuffled_masks = zeros(X, Y, nROIs);  % keep weights
    valid_mask = valid_mask_original;
    
    for i = 1:nROIs
        
        try
            roi = squeeze(originalROIs(:,:,i));
            roi_binary = roi > 0;  % get shape mask
            
            % Get bounding box of ROI
            stats = regionprops(roi_binary, 'BoundingBox');
            bbox = round(stats(1).BoundingBox);  % [x, y, w, h]
            roi_h = bbox(4);
            roi_w = bbox(3);
            
            % Extract the weighted crop
            roi_crop = roi(bbox(2):(bbox(2)+roi_h-1), bbox(1):(bbox(1)+roi_w-1));
            roi_mask_crop = roi_binary(bbox(2):(bbox(2)+roi_h-1), bbox(1):(bbox(1)+roi_w-1));
            
            placed = false;
            
            while placed == false
                
                max_x = X - roi_h + 1;
                max_y = Y - roi_w + 1;
                rand_x = randi(max_x);
                rand_y = randi(max_y);
                
                % Check that placement is entirely inside the valid_mask
                valid_patch = valid_mask(rand_x:(rand_x+roi_h-1), rand_y:(rand_y+roi_w-1));
                
                if all(valid_patch(roi_mask_crop))  % only test where the ROI has non-zero pixels
                    % Place weighted ROI at new location
                    new_mask = zeros(X, Y);
                    new_mask(rand_x:(rand_x+roi_h-1), rand_y:(rand_y+roi_w-1)) = roi_crop;
                    
                    shuffled_masks(:,:,i) = new_mask;
                    valid_mask(rand_x:rand_x+round(roi_h/3), rand_y:rand_y+round(roi_w/3)) = 0;
                    placed = true;
                end
            end
        catch
        end
    end
    
    mstack_shuffle = logical(squeeze(mean(shuffled_masks,3)));
    coverage_fraction_shuffle = sum(mstack_shuffle(:)) / sum(valid_mask(:)); % fraction of covered area
    percent_coverage = (coverage_fraction_shuffle / coverage_fraction) * 100;
    
    if percent_coverage > 95
        coverage_criterion_fulfilled = true;
    end
end
end