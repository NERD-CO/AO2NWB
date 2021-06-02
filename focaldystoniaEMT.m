% 10-20 Hz cutoff, lowpass “near 500 Hz” cutoff,

% 2.5 KHz

% “6th order, high pass filter at 20 Hz”

% rectify abs

% o-code to compute the “linear envelope” with a zero-phase Butterworth filter
% Assume raw data=x(t), xm=mean(x(t)).
% If, as is usually the case, the raw data was high-pass filtered or band-pass filtered, then its mean will be
% zero already.
% y(t) = |x(t)-xm)|
% zButter(t) = y(t) filtered with Butterworth filter in forward and reverse directions
% Pseudo-code to compute the envelope with a rectify-and-mean approach (window width=Tw seconds=Nw
% points)
% y(t)=|x(t)-xm)|
% zMA(t)=(Sum of y(t) from t-Tw/2 to t+Tw/2) / Nw
% 

%% Cd to location and create matrix of EMGs
% cd('C:\Users\Admin\Downloads\Set1\Set1');

cd('C:\Users\johna\Downloads\05_04_2020\05_04_2020\Set1')

matD1 = dir('*.mat');
matD2 = {matD1.name};

depID = 'AbvTrgt_27_05793.mat';
depLoc = contains(matD2,depID);
load(matD2{depLoc})

rawFS = emg.sampFreqHz;

rawEMGr = zeros(length(CEMG_2___01),7);
for ei = 1:7
    
    rawEMGr(:,ei) = transpose(double(eval(['CEMG_2___0',num2str(ei)])));
    
end

rawEMG = rawEMGr(rawFS:length(rawEMGr)-rawFS,:);


%% Setup TimeTable
emgTime = seconds(transpose(0:1/rawFS:(length(rawEMG(:,ei))-1)/rawFS));

emgTT = array2timetable(rawEMG,'RowTimes',emgTime);

%% Step 1 High pass 15 Hz
hiTT = highpass(emgTT,20);

% figure;
% stackedplot(emgTT);
% figure;
% stackedplot(hiTT);

hfig1 = figure('WindowStyle','normal');
htabgroup = uitabgroup(hfig1);
htab1 = uitab(htabgroup, 'Title', 'EMG RAW');
hax1 = axes('Parent', htab1);
stackedplot(emgTT);
htab2 = uitab(htabgroup, 'Title', 'EMG High Pass');
hax2 = axes('Parent', htab2);
stackedplot(hiTT);


%% Step 2 Low pass 500 Hz
lwhiTT = lowpass(hiTT,100);

htab3 = uitab(htabgroup, 'Title', 'EMG HiLo Pass');
hax3 = axes('Parent', htab3);
stackedplot(lwhiTT);


%% Downsample to 2500 Hz
newFS = 2500;
dFsLHtt = retime(lwhiTT,'regular','linear','SampleRate',newFS);

disp(dFsLHtt.Time(end));

htab4 = uitab(htabgroup, 'Title', 'EMG Dn sample');
hax4 = axes('Parent', htab4);
stackedplot(dFsLHtt);


%% Step 3 butter worth

% emgDat = dFsLHtt.Variables;
% 
% bwdFS = zeros(size(emgDat));
% for eii = 1:width(emgDat)
% 
% tlp = lowpass(emgDat(:,eii),20,newFS,'ImpulseResponse','iir','Steepness',0.8);
% 
% bwdFS(:,eii) = tlp;
% 
% end
% 
% bwFStt = dFsLHtt;
% bwFStt.Variables = bwdFS;
% 
% htab5 = uitab(htabgroup, 'Title', 'EMG BW sample');
% hax5 = axes('Parent', htab5);
% stackedplot(bwFStt);

%% Rectify and low pass

emgDat = dFsLHtt.Variables;

rectMsub = zeros(size(emgDat));
for eii = 1:width(emgDat)
    
    tMean = mean(emgDat(:,eii));
    tlp = abs(emgDat(:,eii)-tMean);
    
    rectMsub(:,eii) = tlp;
    
end

rectMS = dFsLHtt;
rectMS.Variables = rectMsub;

htab5 = uitab(htabgroup, 'Title', 'EMG Rect sample');
hax5 = axes('Parent', htab5);
stackedplot(rectMS);


%% amplitude Envelope
emgDat2 = rectMS.Variables;

movMeEMG = zeros(size(emgDat2));
for eii = 1:width(emgDat2)
    
    detM = detrend(emgDat2(:,eii));
    
    tM = movmean(detM,1500);
    tMean = mean(tM);
    tlp = tM-tMean;
    
    movMeEMG(:,eii) = tlpD;
    
end

mmEMG = rectMS;
mmEMG.Variables = movMeEMG;

htab6 = uitab(htabgroup, 'Title', 'EMG MoveM sample');
hax6 = axes('Parent', htab6);
stackedplot(mmEMG);


%% Find peaks
emgDat3 = mmEMG.Variables;


for e3 = 1:1
    
    tSD = std(emgDat3(:,e3));
    tMn = mean(emgDat3(:,e3));
    tTh = tMn + (tSD*2);
    
    XpointsTH = find(emgDat3 > tTh);
    YpointsTH = emgDat3(emgDat3 > tTh);
    
    plot(XpointsTH,YpointsTH,'ro')
    hold on
    plot(1:length(emgDat3),emgDat3(:,e3));
    
end



%%

close all
tMMg = mmEMG(:,1);

%%


pspectrum(tMMg,'FrequencyLimits',[2 50])

%%


% pspectrum(tMMg,'spectrogram','FrequencyLimits',[0.5 50],...
%     'FrequencyResolution',100,'MinThreshold',10,'OverlapPercent',50,'Reassign',true)
%
% pspectrum(batsignal,Fs,'spectrogram','FrequencyResolution',3e3, ...
%     'OverlapPercent',99,'MinTHreshold',-60,'Reassign',true)
%
Fs = newFS;
sigTT = timetable2table(tMMg);
sig1 = table2array(sigTT(:,2));

sig = sig1(500:end-2000);

%
[cfs,f] = cwt(sig,Fs);

sigLen = numel(sig);
t = (0:sigLen-1)/Fs;

hp = pcolor(t,log2(f),abs(cfs));
hp.EdgeAlpha = 0;
ylims = hp.Parent.YLim;
yticks = hp.Parent.YTick;
cl = colorbar;
cl.Label.String = 'magnitude';
axis tight
hold on
title('Scalogram and Instantaneous Frequencies')
xlabel('Seconds');
ylabel('Hz');

ylim([0 10])