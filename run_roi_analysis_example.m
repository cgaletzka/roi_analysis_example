%% RUN_ROI_ANALYSIS_EXAMPLE — synthetic ROI analysis demo
%
% This example walks through:
% 1. Computing a PCA-based similarity metric for ROI shapes across days
% 2. Matching real and shuffled ROIs across 8 simulated days
% 3. Estimating ROI functional dimensionality (Litwin-Kumar et al., 2017)
%
% Reference (for dimensionality metric):
% Litwin-Kumar, A. et al. (2017) Optimal degrees of synaptic connectivity.
% Neuron, 93, 1153-1164.
%
% -------------------------------------------------------------------------

close all; clearvars;
rng(10,'twister');

% Add utils/ folder -------------------------------------------------------
thisFile = '~\run_roi_analysis_example.m';
projRoot = fileparts(thisFile);
addpath(fullfile(projRoot,'utils'));

%% Synthetic dataset parameters -------------------------------------------

params = struct(...
    'threshold', 0.5, ... % threshold for matching
    'shuffle', false, ... % Whether to shuffle ROIs
    'nRois', 50, ... % number of ROIs
    'fovSize', 512, ... % pixels for field of view
    'traceLen', 1000, ... % time points per activity trace
    'nDays', 8, ... % number of consecutive days
    'rBase', [10 25], ... % min and max radius for ROIs
    'centerJitter', 8, ... % position jitter
    'radiusJitter', 8, ... % radius jitter
    'eventProb', 0.01, ... % per-frame spike probability
    'tau', 10, ... % decay constant of Ca kernel
    'noiseSD', 0.025, ... % additive Gaussian noise
    'baselineLevel', 0.2); % Add baseline to synthetic traces

viz = struct(...
    'dayNum', 1, ...
    'offsetK',1.2, ...
    'colTab', lines(params.nRois));

%% Generate synthetic dataset ---------------------------------------------
sim = generate_synthetic_data(params);
disp('... synthetic data created');

%% Plot synthetic dataset -------------------------------------------------
plot_synthetic_dataset(sim,params,viz)
disp('... synthetic data plotted');

%% PCA-based ROI (dis)similarity ------------------------------------------
distance_matrix = compute_pca_similarity(sim,params);
disp('... calculated PCA-based similarity metric');

% --- plot ----------------------------------------------------------------
figure('Name','PCA similarity matrix');
imagesc(distance_matrix);
axis image tight
colorbarHandle = colorbar;
ylabel(colorbarHandle, 'Dissimilarity');
xlabel('ROI index');
ylabel('ROI index');
title(sprintf('PCA-based (dis)similarity — %d days', params.nDays));
box on

%% Match original and shuffled ROIs over all days -------------------------

results = struct('label', {'Real','Shuffled'}, ...
    'shuffle', {false, true}, ...
    'percent', []);

for k = 1:numel(results)
    params.shuffle = results(k).shuffle;
    stats = match_ROIs_across_days(sim, params);
    results(k).percent = [stats.percent_matched] * 100;
end
disp('... Matched real and shuffled ROIs');

percent_matched = results(1).percent;
percent_matched_shuffled = results(2).percent;

ci95 = @(x) tinv(0.975,numel(x)-1) * std(x,0,2) / sqrt(numel(x));
mu   = [mean(percent_matched), mean(percent_matched_shuffled)];
ci   = [ci95(percent_matched), ci95(percent_matched_shuffled)];

% --- plot ----------------------------------------------------------------

figure('Name','Matching accuracy'); hold on
b = bar(mu,'FaceColor','flat','BarWidth',0.6);
b.CData = [viz.colTab(1,:);   viz.colTab(2,:)];
errorbar(1:2, mu, ci, 'k', 'linestyle','none', 'linewidth',1.5);

set(gca,'XTick',1:2,'XTickLabel',{'Matched','Shuffled'});
ylabel('% ROIs correctly matched');
ylim([0, max(mu+ci)+5]);
title(sprintf('ROI matching (mean ±95%% CI, n = %d days)', params.nDays));
box on

text(1:2, mu+ci+2, compose('%.1f%%', mu), 'HorizontalAlignment','center');

%% Compute dimensionality of ROI functional activity

dimAcrossDays = zeros(params.nDays,1);

for d = 1:params.nDays
    dF = reshape([sim(d,:).trace], params.traceLen, []);
    dimAcrossDays(d) = compute_dimensionality(dF);
end
disp('... Calculated functional dimensionality');

muDim = mean(dimAcrossDays);
ciDim = ci95(dimAcrossDays');

% --- plot ----------------------------------------------------------------

figure('Name','ROI functional dimensionality'); hold on
b = bar(muDim, 'FaceColor',viz.colTab(1,:), 'BarWidth',0.5);
errorbar(1, muDim, ciDim, 'k', 'linestyle','none', 'linewidth',1.5);

ylabel('Dimensionality');
title(sprintf('Mean ± 95%% CI over %d days', params.nDays));
ylim([0, params.nRois+5]);
yline(params.nRois,'--','Max possible (= number of ROIs per day)', ...
    'LabelHorizontalAlignment','left','LabelVerticalAlignment','top');
text(1, muDim+ciDim+1.5, sprintf('%.1f', muDim), ...
    'HorizontalAlignment','center');

set(gca,'XTick',[]);
box on
