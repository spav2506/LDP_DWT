function EvalScore(FORMAT,METHOD,SEQ_DIR,SEQ_NAME,IS_SFU,SIGMA_SHUFFLE,SCORE_NAME)

SHUFFLE_SZ = [288 352];
MU_SHUFFLE = (SHUFFLE_SZ+1)/2;

ONE_DEGREE_PXLS_DIEM = 58;
ONE_DEGREE_PXLS_SFU = 24; % 48 for doubled CIF display

[~,~,~,~,~,~,FRMS_CNT,~,IMG_W,IMG_H,~,~] = ...
    ParseInput(SEQ_DIR,FORMAT,SEQ_NAME); FRMS_CNT = FRMS_CNT - 1;

if IS_SFU
    [fixMap1,fixMap2] = GetFixationsSFU(SEQ_DIR,SEQ_NAME,FRMS_CNT,IMG_H,IMG_W);
    GAUSS_SZ = ONE_DEGREE_PXLS_SFU; % 1 degree
else
    [fixMap1,fixMap2] = GetFixationsDIEM(SEQ_DIR,SEQ_NAME,IMG_H,IMG_W);
    
    parname = [SEQ_DIR SEQ_NAME filesep 'par.cfg'];
    if ~exist(parname,'file')
        error(['The program cannnot find ' parname])
    end
    fidPar = fopen(parname,'rt');
    par=fgetl(fidPar);
    while par ~= -1
        if strcmp(par,'ORIGINALHEIGHT')
            par=fgetl(fidPar);
            H = str2double(par);
        end
        par=fgetl(fidPar);
    end
    fclose(fidPar);
    GAUSS_SZ = ONE_DEGREE_PXLS_DIEM*IMG_H/H; % 1 degree
end
gaussMap = fspecial('gaussian',[IMG_H IMG_W],GAUSS_SZ);
gaussMap = gaussMap / max(gaussMap(:));
st = strel('disk',round(GAUSS_SZ/2));

s = size(fixMap1(:,:,1));
vars = [SIGMA_SHUFFLE(1,1) SIGMA_SHUFFLE(2,2)].*(s./SHUFFLE_SZ).^2;
muShuffle = MU_SHUFFLE.*s./SHUFFLE_SZ;
sigmaShuffle = [vars(1) 0;0 vars(2)];

if ~strcmp(METHOD,'IO') && ~strcmp(METHOD,'GAUSS')
    % load result
    resultname = [SEQ_DIR SEQ_NAME filesep 'result_' METHOD '_' FORMAT '.mat'];
    if ~exist(resultname,'file')
        error([resultname ' does not exist!'])
    end
    load(resultname)
    S = double(S)/255;
elseif strcmp(METHOD,'IO')
    S = zeros(size(fixMap2));
    for frame = 1:FRMS_CNT
        S(:,:,frame) = conv2(double(fixMap2(:,:,frame)),gaussMap,'same');
    end
    S = Normalize3d(S);
elseif strcmp(METHOD,'GAUSS')
    S = repmat(gaussMap,[1 1 FRMS_CNT]);
end
KI=[];
if strcmp(SCORE_NAME,'AUC''')
    scoreAUC = nan(FRMS_CNT,1);
    seed = RandStream('mt19937ar','Seed',sum(fixMap1(:)));
    RandStream.setGlobalStream(seed); % reset random variable generation
    for frame=1:FRMS_CNT
        if all(all(fixMap1(:,:,frame)==0))
            continue
        end
        if strcmp(METHOD,'IO') || strcmp(METHOD,'GAUSS') || max(max(S(:,:,frame))) > 0
            % remove uncertaintity
            salMap = imdilate(S(:,:,frame),st);
            salMap = salMap/max(salMap(:));
            scoreAUC(frame) = CalcAUCScore(salMap,fixMap1(:,:,frame),muShuffle,sigmaShuffle);
        end
    if strcmp(METHOD,'IO')
        
            salMap1 = imdilate(S(:,:,frame),st);
            salMap1 = salMap/max(salMap(:));
    end
%     P=histogram(salMap1(:),10);
%     KI=P.Values;
%   
%    H_values(frame,:) = P.Values;
% %       A_Map=salMap1(:);
% RT(frame,:) = A_Map;
    end
%    csvwrite('G:\Pavan_gmail\Other_Required\DCP_Zooming_Saliency\Saliency_exp\IO.csv',H_values)  
%     Score1 = scoreAUC; 
%     Score1(isnan(Score1)==1)=[];
%     S1=mean(Score1);
%     scorename1 = [SEQ_DIR SEQ_NAME filesep 'scoreAUC_' METHOD '_' FORMAT '.mat'];
% save(scorename1,'S1');
% scorename2 = [SEQ_DIR SEQ_NAME filesep 'saliency_values_' METHOD '_' FORMAT '.mat'];
%      scorename1 = [SEQ_DIR SEQ_NAME filesep 'Histogram_values' METHOD '_' FORMAT '.mat'];
    scorename = [SEQ_DIR SEQ_NAME filesep 'score_AUC_' METHOD '_' FORMAT '.mat'];
    save(scorename,'scoreAUC');
%     save(scorename1,'H_values')
%     save(scorename2 ,'RT')
end

if strcmp(SCORE_NAME,'NSS''')
    scoreNSS = nan(FRMS_CNT,1);
    seed = RandStream('mt19937ar','Seed',sum(fixMap1(:)));
    RandStream.setGlobalStream(seed); % reset random variable generation
    for frame=1:FRMS_CNT
        if all(all(fixMap1(:,:,frame)==0))
            continue
        end
        if strcmp(METHOD,'IO') || strcmp(METHOD,'GAUSS') || max(max(S(:,:,frame))) > 0
            % remove uncertaintity
            salMap = imdilate(S(:,:,frame),st);
            salMap = salMap/max(salMap(:));
            scoreNSS(frame) = CalcNSSScore(salMap,fixMap1(:,:,frame),muShuffle,sigmaShuffle);
        end
    end
%     Score2 = scoreNSS; 
%     Score2(isnan(Score2)==1)=[];
%   S2 = mean(Score2);
%      scorename1 = [SEQ_DIR SEQ_NAME filesep 'scoreNSS_' METHOD '_' FORMAT '.mat'];
% save(scorename1,'S2');
    scorename = [SEQ_DIR SEQ_NAME filesep 'score_NSS_' METHOD '_' FORMAT '.mat'];
    save(scorename,'scoreNSS');
end

if strcmp(SCORE_NAME,'JSD''')
    scoreJSD = nan(FRMS_CNT,1);
    seed = RandStream('mt19937ar','Seed',sum(fixMap1(:)));
    RandStream.setGlobalStream(seed); % reset random variable generation
    for frame=1:FRMS_CNT
        if all(all(fixMap1(:,:,frame)==0))
            continue
        end
        if strcmp(METHOD,'IO') || strcmp(METHOD,'GAUSS') || max(max(S(:,:,frame))) >0
            % remove uncertaintity
            salMap = imdilate(S(:,:,frame),st);
            salMap = salMap/max(salMap(:));
            scoreJSD(frame) = CalcJSDScore(salMap,fixMap1(:,:,frame),muShuffle,sigmaShuffle);
        end
    end
%     Score3 = scoreJSD; 
%     Score3(isnan(Score3)==1)=[];
%     S3 = mean(Score3);
%     scorename1 = [SEQ_DIR SEQ_NAME filesep 'scoreJSD_' METHOD '_' FORMAT '.mat'];
% save(scorename1,'S3');    
scorename = [SEQ_DIR SEQ_NAME filesep 'score_JSD_' METHOD '_' FORMAT '.mat'];
    save(scorename,'scoreJSD');
end

if strcmp(SCORE_NAME,'LCC')
    scoreLCC = nan(FRMS_CNT,1);
    seed = RandStream('mt19937ar','Seed',sum(fixMap1(:)));
    RandStream.setGlobalStream(seed); % reset random variable generation
    for frame=1:FRMS_CNT
        if all(all(fixMap1(:,:,frame)==0))
            continue
        end
        if strcmp(METHOD,'IO') || strcmp(METHOD,'GAUSS') || max(max(S(:,:,frame))) > 0
            % remove uncertaintity
            salMap = imdilate(S(:,:,frame),st);
            salMap = salMap/max(salMap(:));
            scoreLCC(frame) = CalcLCCScore(salMap,fixMap1(:,:,frame),gaussMap);
        end
    end
%     Score4 = scoreLCC; 
%     Score4(isnan(Score4)==1)=[];
%    S4 = mean(Score4);
%    scorename1 = [SEQ_DIR SEQ_NAME filesep 'scoreLCCO_' METHOD '_' FORMAT '.mat'];
% save(scorename1,'S4');
    scorename = [SEQ_DIR SEQ_NAME filesep 'score_LCCO_' METHOD '_' FORMAT '.mat'];
    save(scorename,'scoreLCC');
end
