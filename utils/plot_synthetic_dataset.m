function [] = plot_synthetic_dataset(sim,params,viz)

% Get all ROIs on specified day
FOV = false(params.fovSize, params.fovSize, params.nRois);
dF = zeros(params.traceLen, params.nRois);
for r = 1:params.nRois
    FOV(:,:,r) = sim(viz.dayNum,r).mask;
    dF(:,r) = sim(viz.dayNum,r).trace;
end

% Plot ROIs with boundaries first
figure('Name','ROI layout');
ax = gca;
imagesc(zeros(params.fovSize)); axis image off; colormap(gray);  hold(ax,'on');

for r = 1:params.nRois
    B = bwboundaries(FOV(:,:,r));
    plot(ax, B{1}(:,2), B{1}(:,1), ...
        'LineWidth',1.5, 'Color', viz.colTab(r,:));
end
title(ax, sprintf('Day %d - ROI outlines (random colours)', viz.dayNum));

% Plot ROI activity traces
figure('Name','ΔF/F₀ traces'); hold on
% Compute a constant offset large enough so traces never overlap
amp      = max(max(abs(dF)));        % worst-case amplitude
offset   = viz.offsetK * amp;

for r = 1:params.nRois
    plot(dF(:,r) + offset*(r-1), ...
        'Color', viz.colTab(r,:), 'LineWidth', 1);
end
ylim([-offset, offset*(params.nRois)]);
xlabel('Frame'); ylabel('\DeltaF/F_0  +  offset');
title(sprintf('Day %d traces', viz.dayNum));
box on
end