function dim = compute_dimensionality(dF)
% Reference (for dimensionality metric):
% Litwin-Kumar, A. et al. (2017) Optimal degrees of synaptic connectivity.
% Neuron, 93, 1153-1164.
cov_df = cov(dF);
eig_df = eig(cov_df);
num = (sum(eig_df))^2;
denom = sum(eig_df.^2);
dim = num / denom;
end