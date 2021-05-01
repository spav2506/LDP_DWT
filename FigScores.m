clear
close all
clc
SetEnvConst

METHODS = {
%     'PMES'
%     'MAM'
    'PIM-ZEN'
    'PIM-MCS'
%     'MCSDM'
%     'APPROX'
    'OBDL-MRF'
    'MVE-SRN'
%     'AWS'
    'MVE-OBDL'
    'SRDCN-OBDL'
%     'GBVS'
%     'IO'
%     'GAUSS'
    'PROPOSED(DCP)'
    'PROPOSED(LDP)'
% 'SRN+DCP'
% 'SRN+LBP'
%     'LWTRN'
%     'LWTRN-MRF'
%     'DCP'
    };
METHODS_NUM = numel(METHODS);

SCORE_NAMES = {
    'AUC'''
    'NSS'''
    'JSD'''
    'PCC'
    };
N = numel(SCORE_NAMES);

SFU_SEQs = MyDir(SFU_DIR);
DIEM_SEQs = MyDir(DIEM_DIR);
DIEM_SEQs_N = cell(size(DIEM_SEQs));
for i=1:numel(DIEM_SEQs)
    str = cell2mat(DIEM_SEQs(i));
    a = find(str=='_');
    a = [1 a+1];
    DIEM_SEQs_N(i) = cellstr(lower(str(a)));
end
SFU_SEQs_N = cell(size(SFU_SEQs));
for i=1:numel(SFU_SEQs)
    str = cell2mat(SFU_SEQs(i));
    str = lower(str);
    str(1) = upper(str(1));
    SFU_SEQs_N(i) = cellstr(str);
end
SEQs = DIEM_SEQs_N; SEQs(numel(DIEM_SEQs_N)+1:numel(DIEM_SEQs_N)+numel(SFU_SEQs_N)) = SFU_SEQs_N;

numSeq = numel(SEQs);
iMeanScores = zeros(METHODS_NUM,numSeq,N);
pMeanScores = zeros(METHODS_NUM,numSeq,N);
numIFrames = zeros(1,numSeq);
numPFrames = zeros(1,numSeq);

for SCORE = 1:N
    for index=1:numSeq
        if index <= numel(DIEM_SEQs)
            seqIndex = index;
            SEQ_DIR = DIEM_DIR;
            SEQ_NAME = char(DIEM_SEQs(seqIndex));
        else
            seqIndex = index-numel(DIEM_SEQs);
            SEQ_DIR = SFU_DIR;
            SEQ_NAME = char(SFU_SEQs(seqIndex));
        end
        
        [OUT_VDO,IN_VDO,IN_FRAME,IN_MV,IN_MBTYPE,IN_DCT,FRMS_CNT,FRM_RATE,IMG_W,IMG_H,BLK_SZ,HALFPIX] = ...
            ParseInput(SEQ_DIR,FORMAT,SEQ_NAME); FRMS_CNT = FRMS_CNT - 1;
        frameType = ReadFrameTypes(IN_FRAME);
        frameType = frameType(1:FRMS_CNT);
        numIFrames(index) = sum(frameType=='I');
        numPFrames(index) = sum(frameType=='P');
        
        iScores = zeros(sum(frameType=='I'),METHODS_NUM);
        pScores = zeros(sum(frameType=='P'),METHODS_NUM);
        if strcmp(cell2mat(SCORE_NAMES(SCORE)),'AUC''')
            for method =1:METHODS_NUM
                scorename = [SEQ_DIR SEQ_NAME filesep 'score_AUC_' cell2mat(METHODS(method)) '_' FORMAT '.mat'];
%                scorename1 = [SEQ_DIR SEQ_NAME filesep 'scoreAUC_' cell2mat(METHODS(method)) '_' FORMAT '.mat'];
%                load(scorename1)
               load(scorename)
                iScores(:,method) = scoreAUC(frameType=='I');
                pScores(:,method) = scoreAUC(frameType=='P');
            end
%                 mean(pScores)    
        elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'AUC')
            for method =1:METHODS_NUM
                scorename = [SEQ_DIR SEQ_NAME filesep 'score_AUCO_' cell2mat(METHODS(method)) '_' FORMAT '.mat'];
                load(scorename)
                iScores(:,method) = scoreAUCO(frameType=='I');
                pScores(:,method) = scoreAUCO(frameType=='P');
            end
        elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'JSD''')
            for method =1:METHODS_NUM
                scorename = [SEQ_DIR SEQ_NAME filesep 'score_JSD_' cell2mat(METHODS(method)) '_' FORMAT '.mat'];
                load(scorename)
                iScores(:,method) = scoreJSD(frameType=='I');
                pScores(:,method) = scoreJSD(frameType=='P');
            end
%             mean(pScores)
        elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'JSD')
            for method =1:METHODS_NUM
                scorename = [SEQ_DIR SEQ_NAME filesep 'score_JSDO_' cell2mat(METHODS(method)) '_' FORMAT '.mat'];
                load(scorename)
                iScores(:,method) = scoreJSDO(frameType=='I');
                pScores(:,method) = scoreJSDO(frameType=='P');
            end
        elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'NSS''')
            for method =1:METHODS_NUM
                scorename = [SEQ_DIR SEQ_NAME filesep 'score_NSS_' cell2mat(METHODS(method)) '_' FORMAT '.mat'];
                load(scorename)
                iScores(:,method) = scoreNSS(frameType=='I');
                pScores(:,method) = scoreNSS(frameType=='P');
            end
%             mean(pScores)
        elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'NSS')
            for method =1:METHODS_NUM
                scorename = [SEQ_DIR SEQ_NAME filesep 'score_NSSO_' cell2mat(METHODS(method)) '_' FORMAT '.mat'];
                load(scorename)
                iScores(:,method) = scoreNSSO(frameType=='I');
                pScores(:,method) = scoreNSSO(frameType=='P');
            end
        elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'PCC')
            for method =1:METHODS_NUM
                scorename = [SEQ_DIR SEQ_NAME filesep 'score_LCCO_' cell2mat(METHODS(method)) '_' FORMAT '.mat'];
                load(scorename)
                iScores(:,method) = scoreLCC(frameType=='I');
                pScores(:,method) = scoreLCC(frameType=='P');
            end
%             mean(pScores)
        end
        
        invalidFrames = isnan(pScores);
        invalidFrames = sum(invalidFrames,2);
        pScores(invalidFrames==METHODS_NUM,:) = []; % no fixations exist for these frames
        pScores(isnan(pScores)) = 0;
        
        iMeanScores(:,index,SCORE) = mean(iScores);
        pMeanScores(:,index,SCORE) = mean(pScores);
    end
end

fontsize = 9;
for SCORE=1:N
    scoreName = cell2mat(SCORE_NAMES(SCORE));
    im = pMeanScores(:,:,SCORE);
    
    mSeqs = mean(im);
    sSeqs = sqrt(var(im,[],1))/sqrt(size(im,1)); % standard error of the mean (SEM)
    [mSeqs,sortedSeqs] = sort(mSeqs,'descend');
    sSeqs = sSeqs(sortedSeqs);
    mMethods = mean(im,2);
    sMethods = sqrt(var(im,[],2))/sqrt(size(im,2)); %standard error of the mean (SEM)
    [mMethods,sortedMethods] = sort(mMethods,'descend');
    sMethods = sMethods(sortedMethods);
    im = im(sortedMethods,sortedSeqs);
    
    s_x = .12;
    l_x = .72;
    l_x2 = .13;
    l_y2 = .25;
    l_y = .375+METHODS_NUM*.0275;
    
    hf = figure;
    set(hf,'name',[scoreName '(P-frames)'])
    axes('Position',[s_x 1-l_y-l_y2-.02 l_x l_y]);
    
    mn = min(min(im));
    mx = max(max(im));
    im = (im-mn)/(mx-mn)*64;
    imagesc(im), colormap(jet)
    set(gca,'YTick',1:METHODS_NUM,'YTickLabel',METHODS(sortedMethods),'XTickLabel','','fontsize',fontsize)
    SEQsTemp = SEQs(sortedSeqs);
    ax = axis;
    t = text(1:numel(SEQs),ax(4)*ones(1,numel(SEQs)),strcat('\it',SEQsTemp));
    set(t,'HorizontalAlignment','right','VerticalAlignment','top','Rotation',45,'fontsize',fontsize-1);
    
    axes('Position',[l_x+s_x+.01 1-l_y2 l_x2+.01 .25],'visible','off');
    a = num2str(round(mn*10)/10);
    b = num2str(round((mn+mx)/2*10)/10);
    c = num2str(round(mx*10)/10);
    colorbar('location','south','XLim',[0 1],...
        'XTick',[0 1],...
        'XTickLabel',{a,c},'fontsize',fontsize)
    
    axes('Position',[l_x+s_x+.01 1-l_y-l_y2-.02 l_x2 l_y]);
    barh(mMethods,'EdgeColor',[0 .1 .9])
    hold on
    h = herrorbar(mMethods,1:size(im,1),sMethods,'.b');
    set(h(1),'linewidth',2);
    ylim([0 numel(mMethods)]+.5)
    xlim([floor(20*min(mMethods-sMethods))/20,ceil(20*max(mMethods+sMethods))/20])
    set(gca,'YTickLabel','','Ydir','reverse','fontsize',fontsize)
    xlabel(['Avg ' scoreName],'fontsize',fontsize)
    set(gca,'XGrid','on')
   
    if strcmp(cell2mat(SCORE_NAMES(SCORE)),'AUC''')
        set(gca,'XTick',[.5 .65 .8])
    elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'JSD''')
        set(gca,'XTick',[.2 .35 .5])
    elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'NSS''')
        set(gca,'XTick',[.1 .8 1.5])
    elseif strcmp(cell2mat(SCORE_NAMES(SCORE)),'PCC')
        set(gca,'XTick',[.1 .5 .9])
    end
%     axis equal
    axes('Position',[s_x 1-l_y2-.01 l_x l_y2]);
    bar(mSeqs)
    hold on
    errorbar(mSeqs,sSeqs,'.b','linewidth',2)
    xlim([0 numel(mSeqs)]+.5)
    ylim([floor(10*min(mSeqs-sSeqs))/10,ceil(10*max(mSeqs+sSeqs))/10])
    set(gca,'XTickLabel','')
    ylabel(['Avg ' scoreName],'fontsize',fontsize)
    set(gca,'YGrid','on')
    
end
