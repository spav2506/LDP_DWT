% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% estimate saliency maps using different models
clc
clear all
close all
disp('Starting EstimateSaliency')

if ~ispc
    error('The OS is not recognized')
end

SetEnvConst

cd GBVS
gbvs_install
cd ..

seed = RandStream('mt19937ar','Seed',1);
RandStream.setGlobalStream(seed);

for IS_DIEM = 0:0
    if IS_DIEM
        SEQ_DIR = DIEM_DIR;
        ONE_DEGREE_PXLS = 58;
    else
        SEQ_DIR = SFU_DIR;
        ONE_DEGREE_PXLS = 24;
    end
    SEQs = MyDir(SEQ_DIR);
    
    FORMATS = cell(size(QPs));
    for i=1:numel(QPs)
        FORMATS{i} = ['H264_QP' num2str(QPs(i))];
    end
    
    formatIndexs = 1:numel(FORMATS);
    for format = formatIndexs
        FORMAT = cell2mat(FORMATS(format));
        disp('============')
        disp(FORMAT)
        disp('============')
        
        for seqIndex = 1:numel(SEQs)
            SEQ_NAME = char(SEQs(seqIndex));
            disp(SEQ_NAME)
            
            [OUT_VDO,~,IN_FRAME,IN_MV,IN_MBTYPE,IN_DCT,FRMS_CNT,~,IMG_W,IMG_H,BLK_SZ,~] = ...
                ParseInput(SEQ_DIR,FORMAT,SEQ_NAME); FRMS_CNT = FRMS_CNT - 1;
            
            %% pixel-based saliency models
            % decode pixel values
            currentFolder = pwd;
            cd(IN_FRAME)
            if system([ffmpeg_o_run '-i seq.264 -y seq.yuv'])
                error('Fatal error by ffmpeg')
            end
            cd(currentFolder)
            
%             disp('AWS')
%             S = zeros(IMG_H,IMG_W,FRMS_CNT);
%             tStart = tic;
%             for i = 1:FRMS_CNT
%                 im = ReadRGB(OUT_VDO,FRMS_CNT,IMG_H,IMG_W,i);
%                 if max(max(im(:,:,1))) - min(min(im(:,:,1))) > 10 % max(max(im(:,:,1))) > 10
%                     S(:,:,i) = aws(im,1);
%                 end
%             end
%             times = toc(tStart)/FRMS_CNT;
%             disp(times*1000)
%             S = Normalize3d(S);
%             S = uint8(S*255);
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_AWS_' FORMAT '.mat'];
%             save(resultname,'S','times')
%             
%             disp('GBVS')
%             S = zeros(IMG_H,IMG_W,FRMS_CNT);
%             GBVS_param = makeGBVSParams; % get default GBVS params
%             GBVS_param.channels = 'DIOFM';
%             motinfo = [];  % previous frame information, initialized to empty
%             tic
%             for i = 1:FRMS_CNT
%                 [out,motinfo] = gbvs(ReadRGB(OUT_VDO,FRMS_CNT,IMG_H,IMG_W,i), GBVS_param, motinfo );
%                 S(:,:,i) = uint8(out.master_map_resized*255);
%             end
%             times = toc/FRMS_CNT;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_GBVS_' FORMAT '.mat'];
%             save(resultname,'S','times')
%             
%             clear S im
%             delete(OUT_VDO);
            
            %% compressed based saliency models
            
            BLK_H = IMG_H/BLK_SZ; BLK_W = IMG_W/BLK_SZ;
            MBLK_H = IMG_H/16; MBLK_W = IMG_W/16;
            
            mv_x = zeros(BLK_H,BLK_W,FRMS_CNT); % note: start from frame #2
            mv_y = zeros(BLK_H,BLK_W,FRMS_CNT); % note: start from frame #2
            mbType = char(zeros(MBLK_H,MBLK_W,2,FRMS_CNT));
            mbDct = zeros(IMG_H,IMG_W,3,FRMS_CNT,'int16');
            
            frameType = ReadFrameTypes(IN_FRAME);
            frameType = frameType(1:FRMS_CNT);
            for frame = 1:FRMS_CNT
                if frameType(frame) == 'P'
                    [mv_x(:,:,frame), mv_y(:,:,frame)] = ReadMVs(IN_MV, frame, BLK_H, BLK_W, 4);
                end
            end
            for frame = 1:FRMS_CNT
                mbType(:,:,:,frame) = ReadMBTypes(IN_MBTYPE, frame, MBLK_H, MBLK_W);
                mbDct(:,:,:,frame) = ReadDCTs(IN_DCT, frame, IMG_H, IMG_W);
            end
            blkType = char(zeros(BLK_H,BLK_W,2,FRMS_CNT));
            for d = 1:2
                for frame = 1:FRMS_CNT
                    blkType(:,:,d,frame) = kron(mbType(:,:,d,frame),ones(16/BLK_SZ,16/BLK_SZ));
                end
            end
            
            if IS_DIEM
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
                ONE_DEGREE_BLKS = round(ONE_DEGREE_PXLS*IMG_H/H/BLK_SZ);
                ONE_DEGREE_MBLKS = ONE_DEGREE_PXLS*IMG_H/H/16;
            else
                ONE_DEGREE_BLKS = round(ONE_DEGREE_PXLS/BLK_SZ);
                ONE_DEGREE_MBLKS = ONE_DEGREE_PXLS/16;
            end
            
            IN_BITS = [IN_FRAME 'bits_'];
            mem_total = zeros(MBLK_H,MBLK_W,FRMS_CNT);
            for frame = 1:FRMS_CNT
                mem_total(:,:,frame) = ReadBits(IN_BITS, frame, MBLK_H, MBLK_W);
            end

%%
%             disp('OBDL-MRF')
%             tic
%             S = SalOBDL_MRF(mem_total, ONE_DEGREE_MBLKS);
%             times = toc/FRMS_CNT;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_OBDL-MRF_' FORMAT '.mat'];
%             save(resultname,'S','times')
% %%             
% %             disp('MVE-SRN')
%             disp('MVE-SRN')
%             tic
%             [S,S_MVE,S_SRN] = SalMVE_SRN(frameType,blkType,mv_x,mv_y,BLK_SZ,ONE_DEGREE_BLKS,mbDct);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_MVE-SRN_' FORMAT '.mat'];
%             save(resultname,'S','times')
% %             
%             figure (30)
%             imshow(S(:,:,3),[])            
% 

%%

%             disp('PMES')
%             tic
%             S = SalPMES(frameType,mv_x,mv_y,BLK_SZ);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PMES_' FORMAT '.mat'];
%             save(resultname,'S','times')
%%             
%             disp('MAM')
%             tic
%             S = SalMAM(frameType,mv_x,mv_y,BLK_SZ);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_MAM_' FORMAT '.mat'];
%             save(resultname,'S','times')
%%

% % disp('LWTRN-MRF+DCP')
% %             tic
% %             S = Sal_Dcp_Lwtrn(frameType,mbDct,mv_x,mv_y,ONE_DEGREE_BLKS);
% %             num = sum(frameType=='P');
% %             times = toc/num;
% %             disp(times*1000)
% %             resultname = [SEQ_DIR SEQ_NAME filesep 'result_LWTRN-MRF+DCP_' FORMAT '.mat'];
% %             save(resultname,'S','times')
% %             figure (30)
% %             imshow(S(:,:,3),[])            
%% 
%             disp('MVE-OBDL')
%             tic
%             S= MVE_OBDL(frameType,blkType, mv_x, mv_y, BLK_SZ,ONE_DEGREE_BLKS,mem_total);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_MVE-OBDL_' FORMAT '.mat'];
%             save(resultname,'S','times')
%% 
%             disp('SRDCN-OBDL')
%              tic
%             S= SRDCNOBDL(frameType,mbDct,mem_total);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_SRDCN-OBDL_' FORMAT '.mat'];
%             save(resultname,'S','times')
% figure (90)
% imshow(S(:,:,3),[]);
            
% %             disp('PROPOSED')
% %             tic
% %             S = Sal2XPATTERN2(frameType,mbDct,mv_x,mv_y,ONE_DEGREE_BLKS);
% %             num = sum(frameType=='P');
% %             times = toc/num;
% %             disp(times*1000)
% %             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PROPOSED_' FORMAT '.mat'];
% %             save(resultname,'S','times')
% %             
% %             figure(3)
% %             imshow(S(:,:,3),[]);
% %             
%             disp('SRN+DCP')
%             tic
%             S = Sal_Dcp_rn(frameType,mbDct,mv_x,mv_y);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_SRN+DCP_' FORMAT '.mat'];
%             save(resultname,'S','times')
%             figure (30)
%             imshow(S(:,:,3),[])
%%             
%              disp('PROPOSED2')
%             tic
%            [S]= DCP_SRN_saliency(frameType,mbDct,mv_x,mv_y);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PROPOSED2_' FORMAT '.mat'];
%             save(resultname,'S','times')
%             
%             figure (30)
%             imshow(S(:,:,3),[])
%%            
%             disp('PROPOSED2')
%             tic
%            [S]= method_ltp(frameType,mv_x,mv_y,mbDct);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PROPOSED2_' FORMAT '.mat'];
%             save(resultname,'S','times')

%%
            disp('PROPOSED')
            tic
           [S]= method_LDP(frameType,mv_x,mv_y,mbDct);
            num = sum(frameType=='P');
            times = toc/num;
            disp(times*1000)
            resultname = [SEQ_DIR SEQ_NAME filesep 'result_PROPOSED(LDP)_' FORMAT '.mat'];
            save(resultname,'S','times')
%             
% disp('PROPOSED(LDP)')
%             tic
%            [S]= method_LDP(frameType,mv_x,mv_y,mbDct);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PROPOSED(LDP)_' FORMAT '.mat'];
%             save(resultname,'S','times'
%             disp('PROPOSED')
%             tic
%             S = DCP_SRN_saliency(frameType,mbDct,mv_x,mv_y);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PROPOSED_' FORMAT '.mat'];
%             save(resultname,'S','times')
%             figure (30)
%             imshow(S(:,:,3),[])

% disp('PROPOSED3')
%             tic
%            [S]= Imp_ltrp_Zm(frameType,mv_x,mv_y,mbDct);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PROPOSED3_' FORMAT '.mat'];
%             save(resultname,'S','times')

%             figure (30)
%             imshow(S(:,:,3),[])
 %%           
%             disp('SRN+DCP')
%             tic
%             S=Sal_Dcp_rn(frameType, mbDct , mv_x, mv_y);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_SRN+DCP_' FORMAT '.mat'];
%             save(resultname,'S','times')
%             figure (30)
%             imshow(S(:,:,3),[])
%             
%%            
%          disp('SRN+LBP')
%             tic
%             S=Sal_Lbp_rn(frameType, mbDct , mv_x, mv_y);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_SRN+LBP_' FORMAT '.mat'];
%             save(resultname,'S','times')
%             figure (30)
%             imshow(S(:,:,3),[])
%                
 %%           
% %             
%             
% %             disp('LWTRN')
% %             tic
% %             S = Sal_LWTRN(frameType,mbDct);
% %             num = sum(frameType=='P');
% %             times = toc/num;
% %             disp(times*1000)
% %             resultname = [SEQ_DIR SEQ_NAME filesep 'result_LWTRN_' FORMAT '.mat'];
% %             save(resultname,'S','times')
% %             figure (31)
% %             imshow(S(:,:,3),[])
% %             
%%             
% %             disp('LWTRN-MRF')
% %             tic
% %             S = Sal_LWTRN_MRF(frameType,mbDct,ONE_DEGREE_MBLKS);
% %             num = sum(frameType=='P');
% %             times = toc/num;
% %             disp(times*1000)
% %             resultname = [SEQ_DIR SEQ_NAME filesep 'result_LWTRN-MRF_' FORMAT '.mat'];
% %             save(resultname,'S','times')
% %             figure (32)
% %             imshow(S(:,:,3),[])
% 
% 
%%           disp('DCP')
%             tic
%           [ S1 S ]= method_dcp(frameType,mv_x,mv_y);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_DCP_' FORMAT '.mat'];
%             save(resultname,'S','times')
%             figure (32)
%             imshow(S(:,:,3),[])
% % % 
% %             
%             
%%             
%             disp('PIM-ZEN')
%             tic
%             S = SalPIM_ZEN(frameType,blkType,mv_x,mv_y,mbDct,BLK_SZ);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PIM-ZEN_' FORMAT '.mat'];
%             save(resultname,'S','times')
% %%             
%             disp('PIM-MCS')
%             tic
%             S = SalPIM_MCS(frameType,blkType,mv_x,mv_y,mbDct,BLK_SZ);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_PIM-MCS_' FORMAT '.mat'];
%             save(resultname,'S','times')
%%             
%             disp('MCSDM')
%             tic
%             S = SalMCSDM(frameType,mv_x,mv_y,BLK_SZ);
%             num = sum(frameType=='P');
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_MCSDM_' FORMAT '.mat'];
%             save(resultname,'S','times')
%%             
%             disp('APPROX')
%             tic
%             S = SalAPPROX(frameType,mv_x,mv_y,[],BLK_SZ,[]);
%             num = length(frameType);
%             times = toc/num;
%             disp(times*1000)
%             resultname = [SEQ_DIR SEQ_NAME filesep 'result_APPROX_' FORMAT '.mat'];
%             save(resultname,'S','times')
        end
    end
end
fprintf('\nSaliency estimation done!\n')
% EvalScores
% FigSaliencyMap