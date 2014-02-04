function [waves,artifacts] = throwArtifacts(noisyWaves,threshold)
% waves = throwArtifacts(wavesWithNoise,standardDeviations)
% Function throwArtifacts finds waves that have data points greater than
% a specified multiple of the mean of the standard deviations of each data
% point in the triggered waves. Default threshold is ten standard
% deviations.
if nargin < 2
    threshold = 10;
end
stdev = threshold*std(noisyWaves);
artifactsIndeces = zeros(length(noisyWaves(:,1)),1);
for i = 1:length(noisyWaves(:,1))
    if any(abs(noisyWaves(i,:)) > stdev)
        artifactsIndeces(i) = 1;
    end
end
waves = noisyWaves;
artifacts = waves(artifactsIndeces == 1,:);
waves(artifactsIndeces == 1,:) = [];

end

