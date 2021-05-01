% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% evaluate models according to different scores

disp('Starting EvalScores')

SetEnvConst
METHODS = {
    'MVE-SRN'
    'OBDL-MRF'
%     'PMES'
%     'MAM'
    'PIM-ZEN'
    'PIM-MCS'
%     'MCSDM'
%     'APPROX'
%      'AWS'
%     'GBVS'
%     'GAUSS'
%     'IO'
    
% 'Humansaliency'
'SRDCN-OBDL'
'PROPOSED'
% 'PROPOSED(LDP)'
% 'PROPOSED(DCP)'
'MVE-OBDL'
% 'DCP'
% 'SRN+DCP'
% 'SRN+LBP'
% 'DCP'
    };
methodIndexes = 1:numel(METHODS);
shuffleName = 'shuffleDIEM.mat';
if ~exist(shuffleName,'file')
    SIGMA_SHUFFLE_DIEM = ShuffleDIEM;
    save(shuffleName,'SIGMA_SHUFFLE_DIEM');
else
    load(shuffleName);
end
shuffleName = 'shuffleSFU.mat';
if ~exist(shuffleName,'file')
    SIGMA_SHUFFLE_SFU = ShuffleSFU;
    save(shuffleName,'SIGMA_SHUFFLE_SFU');
else
    load(shuffleName);
end

for DIEM=[false true]
    if DIEM
        disp('--------')
        disp('- DIEM -')
        disp('--------')
        SEQ_DIR = DIEM_DIR;
        IS_SFU = 0;
        SIGMA_SHUFFLE = SIGMA_SHUFFLE_DIEM;
    else
        disp('-------')
        disp('- SFU -')
        disp('-------')
        SEQ_DIR = SFU_DIR;
        IS_SFU = 1;
        SIGMA_SHUFFLE = SIGMA_SHUFFLE_SFU;
    end
    SEQs = MyDir(SEQ_DIR);
    
    FORMATS = cell(size(QPs));
    for i=1:numel(QPs)
        FORMATS{i} = ['H264_QP' num2str(QPs(i))];
    end
    
    formatIndexs = 1:numel(FORMATS);
    
    for formatIndex = formatIndexs
        format = cell2mat(FORMATS(formatIndex));
        disp(format)
        disp('******************')
        for methodIndex = methodIndexes
            METHOD = cell2mat(METHODS(methodIndex));
            disp(METHOD)
            disp('~~~~~')
            for seqIndex = 1:numel(SEQs)
                SEQ_NAME = char(SEQs(seqIndex));
                disp(SEQ_NAME)
              EvalScore(format,METHOD,SEQ_DIR,SEQ_NAME,IS_SFU,SIGMA_SHUFFLE,'AUC''');
              EvalScore(format,METHOD,SEQ_DIR,SEQ_NAME,IS_SFU,SIGMA_SHUFFLE,'NSS''');
%                 if strcmp(format,FORMAT)
                    EvalScore(format,METHOD,SEQ_DIR,SEQ_NAME,IS_SFU,SIGMA_SHUFFLE,'JSD''');
                    EvalScore(format,METHOD,SEQ_DIR,SEQ_NAME,IS_SFU,SIGMA_SHUFFLE,'LCC');
%                 end
            end
        end
    end
end

disp('================')
disp('EvalScores done!')
FigScores