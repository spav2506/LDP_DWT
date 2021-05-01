% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% calculate the score of Area Under Curve 
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
%     auc: (integer value) area under curve score
%
% if Gaussian parameters are not defined, a uniform distribution is used

function auc = CalcAUCScore(salMap,fixMap,muShuffle,sigmaShuffle)

RAND_CNT = 100;

n = max(fixMap(:));
indexes = [];
for i=1:n
    index = find(fixMap>=i);
    indexes = [indexes;index];
end
fixSal = salMap(indexes);
fixNum = length(fixSal);

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

aucs=zeros(RAND_CNT,1);
for sample=1:RAND_CNT
    nonFixSal = nonFixSals(:,sample);
    
    x = fixSal(fixSal>0);
    y = nonFixSal(nonFixSal>0);
    BINS = [x;y];
    BINS = sort(BINS,'descend')';
    
    tprs = zeros(length(BINS)+2,1);
    fprs = zeros(length(BINS)+2,1);
    tprs(end) = 1;
    fprs(end) = 1;
    
    index = 2;
    for step = BINS
        tprs(index) = sum((fixSal >= step))/fixNum;
        fprs(index) = sum((nonFixSal >= step))/fixNum;
        index = index+1;
    end
    aucs(sample) = trapz(fprs,tprs);
end

auc = mean(aucs);
