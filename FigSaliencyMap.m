clear
close all
clear all

SetEnvConst

METHODS = {
% %     'PMES'
% %     'MAM'
    'PIM-ZEN'
    'PIM-MCS'
% %     'MCSDM'
% %     'APPROX'
    'OBDL-MRF'
    'MVE-SRN'
% %     'AWS'
    'MVE-OBDL'
    'SRDCN-OBDL'
% %     'GBVS'
% %     'Humansaliency'
    'PROPOSED(LDP)'
%     'IO'
    };
METHODS_NUM = numel(METHODS);

ONE_DEGREE_PXLS_DIEM = 58;
ONE_DEGREE_PXLS_SFU = 24; % 48 for doubled CIF display

for seq_dir=1
    if seq_dir == 1
        SEQ_DIR = SFU_DIR;
        SFU = true;
        DIEM = false;
        FRM = 25;
        SEQs = {
%             'BUS'
%             'MOBILE'
%             'HALL'
%             'CREW'
%             'CITY'
%             'TEMPETE'
%             'STEFAN'
%              'DIVING'
             'GOLF_SWING_SIDE'
            };
    else
        SEQ_DIR = DIEM_DIR;
        SFU = false;
        DIEM = true;
        FRM = 150;
        SEQs = {
            'advert_iphone'
            'one_show'
            };
     end
    
    for seqIndex = 1:numel(SEQs)
        SEQ_NAME = char(SEQs(seqIndex));
        
        [OUT_VDO,IN_VDO,IN_FRAME,IN_MV,IN_MBTYPE,IN_DCT,FRMS_CNT,FRM_RATE,IMG_W,IMG_H,BLK_SZ,HALFPIX] = ...
            ParseInput(SEQ_DIR,FORMAT,SEQ_NAME); FRMS_CNT = FRMS_CNT - 1;
        
        BLK_H = IMG_H/BLK_SZ; BLK_W = IMG_W/BLK_SZ;
        [mv_x,mv_y] = ReadMVs(IN_MV, FRM, BLK_H, BLK_W, HALFPIX);
        currentFolder = pwd;
%       figure,  imshow(IN_FRAME)
        cd(IN_FRAME)
        if system([ffmpeg_o_run ' -i seq.264 -y seq.yuv'])
            error('Fatal error by ffmpeg: not run from all blades!')
        end
        cd(currentFolder)        
        img = ReadRGB(OUT_VDO, FRMS_CNT, IMG_H, IMG_W, FRM);
        rgb = img;
        rgb = double(rgb)/255;
        delete(OUT_VDO);
        img(:) = 0;
        figure, imshow(img,'Border','tight','InitialMagnification',100);
        hold on, quiver((1:BLK_W)*BLK_SZ,(1:BLK_H)*BLK_SZ,mv_y,mv_x,1,'y')
        set(gcf,'name',SEQ_NAME)
        
%         if SFU
%             [fixMap1,fixMap2] = GetFixationsSFU(SEQ_DIR,SEQ_NAME,FRMS_CNT,IMG_H,IMG_W);
%             GAUSS_SZ = ONE_DEGREE_PXLS_SFU; % 1 degree
%         end
        if DIEM
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
%         gaussMap = fspecial('gaussian',[IMG_H IMG_W],GAUSS_SZ);
%         gaussMap = gaussMap / max(gaussMap(:));
        
        for methodIndex=1:METHODS_NUM
            METHOD = cell2mat(METHODS(methodIndex));
            if ~strcmp(METHODS(methodIndex),'IO') && ~strcmp(METHODS(methodIndex),'GAUSS')
                % load result
                resultname = [SEQ_DIR SEQ_NAME filesep 'result_' METHOD '_' FORMAT '.mat'];
                if ~exist(resultname,'file')
                    continue
                end
                load(resultname)
                S = double(S)/256;
            elseif strcmp(METHODS(methodIndex),'IO')
                S = zeros(size(fixMap2));
                for frame = 1:FRMS_CNT
                    S(:,:,frame) = conv2(double(fixMap2(:,:,frame)),gaussMap,'same');
                end
                S = Normalize3d(S);
            elseif strcmp(METHODS(methodIndex),'GAUSS')
                S = repmat(gaussMap,[1 1 FRMS_CNT]);
            end
            
            S = S(:,:,FRM);
            im = (rgb+ind2rgb(uint8(S*64),jet))/2;
            figure, title('Fixation'), imshow(im,'Border','tight','InitialMagnification',100)
            set(gcf,'name',cell2mat(METHODS(methodIndex)))
        end
    end    
end
figure , imshow(uint8(255.*(rgb)),'Border','tight','InitialMagnification',100)