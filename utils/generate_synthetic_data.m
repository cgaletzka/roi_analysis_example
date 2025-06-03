function sim = generate_synthetic_data(params)

% basic function for drawing random numbers
randInt = @(lo,hi,varargin) lo + floor((hi-lo+1).*rand(varargin{:}));

% initialize results structure
sim = repmat(struct('mask', [], 'center', [], 'radius', [], 'trace', []), ...
    params.nDays, params.nRois);

% Generate Day 1 ROIs (serve as template for following day)
templateCenter = [randInt(max(params.rBase), params.fovSize-max(params.rBase), params.nRois, 1), ...
    randInt(max(params.rBase), params.fovSize-max(params.rBase), params.nRois, 1)];
templateRadius = randInt(params.rBase(1), params.rBase(2), params.nRois, 1);

% Calcium kernel
k = exp(-(0:49)/params.tau);
k = k / sum(k);

% Field of view
[X, Y] = meshgrid(1:params.fovSize, 1:params.fovSize);

% Loop over days and ROIs
for d = 1:params.nDays
    ctr = templateCenter + round(params.centerJitter*randn(params.nRois,2));
    rad = templateRadius + round(params.radiusJitter*randn(params.nRois,1));
    templateCenter = ctr;
    templateRadius = rad;
    
    rad = max(rad,3);
    
    for r = 1:params.nRois
        cx = ctr(r,1);
        cy = ctr(r,2);  rr = rad(r);
        
        sim(d,r).mask = ((X-cx).^2 + (Y-cy).^2) <= rr^2;
        sim(d,r).center = [cx cy];
        sim(d,r).radius = rr;
        
        spikes = rand(params.traceLen,1) < params.eventProb;
        f_raw = params.baselineLevel + conv(spikes, k, 'same') + params.noiseSD*randn(params.traceLen,1);
        F0  = prctile(f_raw,8);
        sim(d,r).trace = (f_raw - F0) / F0;
    end
end

end