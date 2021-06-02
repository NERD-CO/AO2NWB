% Get file names associated with current depth header
dir_sel = cellfun(@(x) contains(x, depth_temp{1}), dir_temp);
dirtemp_sel = sort(dir_temp(dir_sel));

% Initialize variables
CRAW = {};
timestamp = [];

for chan_sel = 1:num_chan
    CRAW{chan_sel} = [];
end

% Loop through data files for each depth
for dir_idx = 1:length(dirtemp_sel)
    data_sel = load(fullfile(dir_raw, dirtemp_sel{dir_idx}));

    fs = floor(data_sel.CRAW_01_KHz * 1000);

    timestamp(dir_idx, 1) = floor(data_sel.CRAW_01_TimeBegin * fs);
    timestamp(dir_idx, 2) = floor(data_sel.CRAW_01_TimeEnd * fs);

    for chan_sel = 1:num_chan
        header_lfp = 'CRAW_0';
        chan_num = chan_sel;
        if chan_sel > 5
            header_lfp = 'CMacro_RAW_0';
            chan_num = chan_sel - 5;
        end
        CRAW{chan_sel} = cat(2, CRAW{chan_sel}, eval(['double(data_sel.' header_lfp char(num2str(chan_num)) ') * data_sel.' header_lfp char(num2str(chan_num)) '_BitResolution / data_sel.' header_lfp char(num2str(chan_num)) '_Gain' ]));
    end
end

clear data_sel
CDIG = [];

merged_file_time = 0;   %% Menem - add this line

for dir_idx = 1:length(dirtemp_sel)
    data_sel = load(fullfile(dir_raw, dirtemp_sel{dir_idx}));


    isfield(data_sel, 'CDIG_IN_1_Up');   %% Menem - add this line
    Are_there_Up_triggers_in_this_file = ans;   %% Menem - add this line


    if Are_there_Up_triggers_in_this_file==1  %% Menem - add this line
        CDIG = [CDIG (data_sel.CDIG_IN_1_Up+merged_file_time*fs+(data_sel.CDIG_IN_1_TimeBegin-data_sel.CRAW_01_TimeBegin)*fs)];  %% Menem - add this line
    end  %% Menem - add this line

    %         if (dir_idx == 3)
    %             time_start = data_sel.CLFP_01_TimeBegin;   % Menem - remove this
    %         end% Menem - remove this
    %         if isfield(data_sel, 'CDIG_IN_1_Up')% Menem - remove this
    %             timestamp_temp = cat(1, timestamp_temp , floor([data_sel.CLFP_01_TimeBegin data_sel.CLFP_01_TimeEnd]));% Menem - remove this
    %             time_current = data_sel.CDIG_IN_1_TimeBegin - time_start;% Menem - remove this
    %             dig_fs =data_sel.CDIG_IN_1_KHz * 1000;% Menem - remove this
    %             pnt_current = time_current*dig_fs + 1;% Menem - remove this
    %             CDIG = cat(2, CDIG, ((data_sel.CDIG_IN_1_Up + pnt_current) ./ dig_fs));% Menem - remove this
    %         end% Menem - remove this
    merged_file_time = merged_file_time+data_sel.CRAW_01_TimeEnd-data_sel.CRAW_01_TimeBegin;  %% Menem - add this line

    clear data_sel
end
CDIG = CDIG / fs;

CDIG2 = [];
timestamp_temp = [];
time_diff = [];
last_time_end = 0;
for dir_idx = 1:length(dirtemp_sel)
    data_sel = load(fullfile(dir_raw, dirtemp_sel{dir_idx}));
    if (dir_idx == 1)
        time_start = data_sel.CRAW_01_TimeBegin;
    end
    if isfield(data_sel, 'CDIG_IN_1_Up')
        timestamp_temp = cat(1, timestamp_temp , floor([data_sel.CRAW_01_TimeBegin data_sel.CRAW_01_TimeEnd]));
        time_current = data_sel.CDIG_IN_1_TimeBegin - time_start;
        dig_fs =data_sel.CDIG_IN_1_KHz * 1000;
        pnt_current = time_current*dig_fs + 1;
        CDIG2 = cat(2, CDIG2, ((data_sel.CDIG_IN_1_Up + pnt_current) ./ dig_fs));
    end
    assert(last_time_end <= floor(data_sel.CRAW_01_TimeBegin));
    if (dir_idx ~= 1)
        assert(abs(last_time_end - floor(data_sel.CRAW_01_TimeBegin))/fs < .5); % does not assert
    end
    last_time_end = floor(data_sel.CRAW_01_TimeEnd);
    clear data_sel
end

marker_count{depth_idx, 1} = depth_temp{depth_idx};
marker_count{depth_idx, 2} = length(CDIG);
marker_list{depth_idx} = CDIG;

clear data_sel
clearvars -except CINFO CRAW CDIG timestamp num_chan fs_lfp fs_raw fs dir_temp depth_temp depth_idx marker_count marker_list subj_char dir_raw out_dir


figure;
spk_fs = floor(CSPK_01_KHz * 1000);

CSPK_01_Mod = (double(CSPK_01) * CSPK_01_BitResolution) / CSPK_01_Gain;

spk_seCs = seconds(0:1/spk_fs:(length(CSPK_01)-1)/spk_fs);

spk_tt = timetable(transpose(spk_seCs),transpose(CSPK_01),transpose(CSPK_01_Mod));

stackedplot(spk_tt)

%%
figure;
lfp_fs = floor(CLFP_01_KHz * 1000);

CLFP_01_Mod = (double(CLFP_01) * CLFP_01_BitResolution) / CLFP_01_Gain;

lfp_seCs = seconds(0:1/lfp_fs:(length(CLFP_01)-1)/lfp_fs);

lfp_tt = timetable(transpose(lfp_seCs),transpose(CLFP_01),transpose(CLFP_01_Mod));

stackedplot(lfp_tt)