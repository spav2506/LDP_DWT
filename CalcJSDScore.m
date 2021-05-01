% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% calculate the score of Jensen–Shannon Divergence
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
%     jsd: (integer value) Jensen–Shannon divergence score
%
% if Gaussian parameters are not defined, a uniform distribution is used

function jsd = CalcJSDScore(salMap,fixMap,muShuffle,sigmaShuffle)

RAND_CNT = 100;
STEP = .1;
BINS = .05:STEP:.95;

n = max(fixMap(:));
indexes = [];
for i=1:n
    index = find(fixMap>=i);
    indexes = [indexes;index];
end
fixSal = salMap(indexes);
fixNum = length(fixSal);
fixHistO = hist(fixSal,BINS);

if nargin < 3
    nonFixSalTotal = salMap(fixMap==0)';
    nonFixNum = length(nonFixSalTotal);
    nonFixSals = nonFixSalTotal(randi([1,nonFixNum],[fixNum,RAND_CNT]));
else
    x = round(mvnrnd(muShuffle,sigmaShuffle,fixNum*RAND_CNT*2));
    % remove positions outside of the image border
    x(x(:,1)<1,:) = []; x(x(:,1)>size(salMap,1),:) = [];
    x(x(:,2)<1,:) = []; x(x(:,2)>size(salMap,2),:) = [];
    % obtain correspondance position in 1-d
    p = (x(:,2)-1)*size(salMap,1)+x(:,1);
    % remove fixation points
    fixations = find(fixMap~=0);
    [~,index,~] = intersect(p,fixations);
    p(index) = [];
    % obtain control points for non-fixations
    nonFixSals = salMap(p(1:fixNum*RAND_CNT));
    nonFixSals = reshape(nonFixSals,fixNum,RAND_CNT);
end

jsds = zeros(RAND_CNT,1);
for sample=1:RAND_CNT
    nonFixSal = nonFixSals(:,sample);
    nonFixHist = hist(nonFixSal,BINS);
    
    indexes = find(nonFixHist~=0 | fixHistO ~= 0);
    fixHist = fixHistO(indexes);
    fixHist = fixHist/sum(fixHist);
    nonFixHist = nonFixHist(indexes);
    nonFixHist = nonFixHist/sum(nonFixHist);
    R = (fixHist+nonFixHist)/2;
    
    P = nonFixHist .* log2(nonFixHist./R);
    P(isnan(P)) = 0;
    Q = fixHist .* log2(fixHist./R);
    Q(isnan(Q)) = 0;
    
    jsds(sample) = (sum(P)+sum(Q))/2;
end

jsd = mean(jsds);
