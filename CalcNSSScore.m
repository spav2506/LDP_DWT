% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% calculate the score of normalized scanpath saliency
%
% Input
%     salMap: (2-D matrix) predicted saliency map
%     fixMap: (2-D matrix) discrete fixation map
%     muShuffle: (integer value) expectation of Gaussian distribution
%        fitted to shuffle fixations
%     sigmaShuffle: (integer value) standard deviation of Gaussian
%        distribution fitted to shuffle fixations
%
% Output
%     nss: (integer value) normalized scanpath saliency score
%
% if Gaussian parameters are not defined, a uniform distribution is used

function nss = CalcNSSScore(salMap,fixMap,muShuffle,sigmaShuffle)

if nargin < 3
    mu = mean(salMap(:));
    sigma = std(salMap(:));
else
    [X1,X2] = ndgrid(1:size(salMap,1),1:size(salMap,2));
    gaussShuffle = mvnpdf([X1(:) X2(:)],muShuffle,sigmaShuffle);
    gaussShuffle(fixMap~=0) = 0;
    gaussShuffle = gaussShuffle/sum(gaussShuffle);
    mu = sum(salMap(:).*gaussShuffle);
    sigma = sqrt(var(salMap(:),gaussShuffle));
end

salMap = (salMap-mu)/sigma;

n = max(fixMap(:));
indexes = [];
for i=1:n
    index = find(fixMap>=i);
    indexes = [indexes;index];
end

nss = mean(salMap(indexes));
