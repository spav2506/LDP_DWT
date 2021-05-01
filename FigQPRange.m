clear
close all

SetEnvConst

SCORE_NAMES = {
    'AUC'''
    'NSS'''
    'JSD'''
    };
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
%     'GBVS'
    'SRDCN-OBDL'
    'MVE-OBDL'
    'PROPOSED(DCP)'
    'PROPOSED(LDP)'
    };

SEQs_DIEM = MyDir(DIEM_DIR);
SEQs_SFU = MyDir(SFU_DIR);

FORMATS = cell(size(QPs));
for i=1:numel(QPs)
    FORMATS{i} = ['H264_QP' num2str(QPs(i))];
end

numSeq = numel(SEQs_DIEM)+numel(SEQs_SFU);
meanScores = zeros(numSeq,numel(FORMATS),numel(METHODS));

if exist('psnr.mat','file')
    load('psnr.mat')
else
    psnr = zeros(numel(FORMATS),numSeq);
    for format = 1:numel(FORMATS)
        FORMAT = cell2mat(FORMATS(format));
        index = 1;
        for seq = 2
            if seq==1
                SEQ_DIR = DIEM_DIR;
            else
                SEQ_DIR = SFU_DIR;
            end
            SEQs = MyDir(SEQ_DIR);
            for seqIndex=1:numel(SEQs)
                SEQ_NAME = char(SEQs(seqIndex));
                [OUT_VDO,IN_VDO,IN_FRAME,IN_MV,IN_MBTYPE,IN_DCT,FRMS_CNT,FRM_RATE,IMG_W,IMG_H,BLK_SZ,HALFPIX] = ...
                    ParseInput(SEQ_DIR,FORMAT,SEQ_NAME); FRMS_CNT = FRMS_CNT - 1;
                yIn = ReadYUV(IN_VDO, FRMS_CNT, IMG_H, IMG_W);
                currentFolder = pwd;
                cd(IN_FRAME)
                if system([ffmpeg_o_run ' -i seq.264 -y seq.yuv'])
                    error('Fatal error by ffmpeg: not run from all blades!')
                end                
                cd(currentFolder)
                yOut = ReadYUV(OUT_VDO, FRMS_CNT, IMG_H, IMG_W);
                delete(OUT_VDO);
                D = abs(yIn(:)-yOut(:));
                clear yIn yOut
                mse = D'*D/numel(D);
                clear D
                psnr(format,index) = 10*log10((255^2)/mse);
                index=index+1;
            end
        end
    end
    save('psnr','psnr')
end
m_psnr = mean(psnr,2);

for scoreIndex = 1:numel(SCORE_NAMES)
    SCORE_NAME = cell2mat(SCORE_NAMES(scoreIndex));
    for methodIndex = 1:numel(METHODS)
        METHOD = cell2mat(METHODS(methodIndex));
        disp(METHOD)
        for format = 1:numel(FORMATS)
            FORMAT = cell2mat(FORMATS(format));
            for index=1:numSeq
                if index <= numel(SEQs_DIEM)
                    seqIndex = index;
                    SEQ_DIR = DIEM_DIR;
                    SEQ_NAME = char(SEQs_DIEM(seqIndex));
                else
                    seqIndex = index-numel(SEQs_DIEM);
                    SEQ_DIR = SFU_DIR;
                    SEQ_NAME = char(SEQs_SFU(seqIndex));
                end
                
                if strcmp(SCORE_NAME,'AUC''')
                    scorename = [SEQ_DIR SEQ_NAME filesep 'score_AUC_' METHOD '_' FORMAT '.mat'];
                    load(scorename)
                    scores = scoreAUC;
                elseif strcmp(SCORE_NAME,'NSS''')
                    scorename = [SEQ_DIR SEQ_NAME filesep 'score_NSS_' METHOD '_' FORMAT '.mat'];
                    load(scorename)
                    scores = scoreNSS;
                elseif strcmp(SCORE_NAME,'JSD''')
                    scorename = [SEQ_DIR SEQ_NAME filesep 'score_JSD_' METHOD '_' FORMAT '.mat'];
                    load(scorename)
                    scores = scoreJSD;
                elseif strcmp(SCORE_NAME,'LCC''')
                    scorename = [SEQ_DIR SEQ_NAME filesep 'score_LCC_' METHOD '_' FORMAT '.mat'];
                    load(scorename)
                    scores = scoreLCC;
                elseif strcmp(SCORE_NAME,'PCC')
                    scorename = [SEQ_DIR SEQ_NAME filesep 'score_LCCO_' METHOD '_' FORMAT '.mat'];
                    load(scorename)
                    scores = scoreLCC;
                end
                [~,~,IN_FRAME,~,~,~,~,~,~,~,~,~] = ParseInput(SEQ_DIR,FORMAT,SEQ_NAME);
                frameType = ReadFrameTypes(IN_FRAME); frameType=frameType(1:end-1);
                scores(frameType=='I') = [];
                scores(isnan(scores)) = []; % no fixations exist for these frames or the method is not able to produce saliency (like I-frames for PMES)
                meanScores(index,format,methodIndex) = mean(scores);
            end
        end
    end
    %%
    
    figure
    ha = axes;
    p = get(ha,'Position');
    set(ha,'Position',p-[0 0 .15 0]); 
    fontsize = 9;
    ColorSet = ['k','r','g','c','m','r','k','g','c','m','y','r','b'];
    linestyles = cellstr(char('-','--',':','-','--','-',':','--',':','-',':','--','-'));
    Markers=['o','o','^','^','*','v','*','v','s','s','*','o','v'];
    
    hold on
    for methodIndex = 1:numel(METHODS)
        scores = meanScores(:,:,methodIndex);
        m = mean(scores);
        plot(m_psnr,m,[linestyles{methodIndex} Markers(methodIndex)], 'color',ColorSet(methodIndex),'linewidth',2,'markersize',8)
    end
    xlim([m_psnr(end)-1,m_psnr(1)+1])
    grid on
    xlabel('Average PSNR (dB)','fontsize',fontsize)
    ylabel(['Average ' SCORE_NAME],'fontsize',fontsize)
    hleg = legend(METHODS,'fontsize',fontsize,'Location','EastOutside','Box','on');
    p = get(hleg,'position');
    set(hleg,'position',p+[.24 -numel(METHODS)*.02 0 numel(METHODS)*.04])
end