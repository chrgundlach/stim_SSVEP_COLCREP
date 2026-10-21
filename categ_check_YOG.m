function categ_check_YOG(subject,block)

%-------------------------------------------------------
%presents squares for categorisaton, to get category boundary
%for each individual observer for the YOG (yellow-orange; yellow-green) 
%stimulus evaluation of Stormer and Alvarez inhibition model.
%
%inputs - subject: participant no, block - 1 for yellow/orange, 2 for
%yellow/green direction of hues
%
%experimenter can use categ_data_analysis.m to extract boundary; 
%
% produces the following files:
% participantnumber_YOG_categ.result: results from all trials, all conditions
%
%written by jasna martinovic,oct 2026
%---------------------------------------------------------
fclose('all');
close all;

AssertOpenGL;     %exit if obsolete version of PTB

str_sub = num2str(subject);
str_bl=num2str(block);
%--------------------------------------------------------
% part of path, where data will be stored:
path_name='C:\Users\jmartino\';
%--------------------------------------------------------

%----------------------------------------
%OPEN FILE FOR RESULTS
%----------------------------------------
% each trial is recorded in a single line in this file
fid1=fopen(sprintf('%s\%s_%s_YOG_categ.result',path_name,str_sub,str_bl),'w');

%==================================
% Experiment
%==================================
%define screen and stimulus configuration parameters
whichScreen=max(Screen('Screens')); %select secondary display (if available)
%for debugging
ScrWidth=900; ScrHeight=900;
[window,mainRect]=Screen('OpenWindow',whichScreen,128,[0,0,ScrWidth,ScrHeight]);
%for real
%[window,mainRect]=Screen('OpenWindow',whichScreen);

maxLevel = Screen('ColorRange', window);

%NORMAN - PLEASE REPLACE THIS SECTION WITH THE WAY YOU HANDLE YOUR GAMUT
%load my gamma table to video screen 
%    load gammatable256.mat
%    originalCLUT=Screen('LoadNormalizedGammaTable',window,gammatable);

%let us choose a background level in CIE LCh
%NORMAN - PLEASE SET l LEVEL THAT YOU FIND PRODUCES GOOD GAMUT 
L=120;
C=40; %this should be maximal chroma used in SSVEP expt
%JASNA - I'VE HARDCODED A FIXATION POINT HERE, NEED TO DECIDE WHAT LEVEL WE
%WANT IN BETWEEN
dark=[50,50,50];
%JASNA - CHECK IN FAIRCHILDS BOOK OR RUN HUE SETTINGS PRELIM ON A FEW OBSERVERS
Yelang=101; %hue angle of yellow
angdist=30; %angular distance into Stormer and Alvarez (2014) putative inhibition zone
%JASNA - CHECK THAT 4.5DEG IS 1 JND I.E. 2.3 DELTA E
stepsize=5; %step in hue angle - should be just above a JND 

%bgnd
WP_LCh=[L, 0, 0]; 

%now decide which stimulus range to generate
if block==1
    hues=(Yelang-angdist):stepsize:Yelang;
elseif block==2
    hues=Yelang:stepsize:(Yelang+angdist);
end

%our stimulus colours, in LCh
abTable.LCh=[repmat(L,numel(hues),1),repmat(C,numel(hues),1), hues'];
%transform into LAB
abTable.Lab = lch2lab([WP_LCh; abTable.LCh]);
%now into XYZ
abTable.XYZ = lab2xyz(abTable.Lab);
%now get RGB coordinates
%NORMAN - I WOULD QUITE LIKE PROPIX/d65 COORDINATES TO BE OUTSIDE OF SCRIPT
%AND FED AS INPUTS
abTable.ppRGB = xyz2rgb_custom(abTable.XYZ,[0.665 0.321], [0.172 0.726], [0.163 0.039], [0.3127 0.3290]);

%these are all my stimulus colours 
values=abTable.ppRGB(2:size(abTable.ppRGB,1),:);

%set window background to GRAYdz
  Screen('FillRect',window,abTable.ppRGB(1,:));
  Screen('Flip',window);
%remove mouse cursor from screen
HideCursor;

%now set up stimulus position and size
shsiz=80; 
stimkoords=[0 0 shsiz shsiz];
[xCenter, yCenter] = RectCenter(mainRect);
centeredRect = CenterRectOnPointd(stimkoords, xCenter, yCenter);

%fixation cross
fixsz=5;
fixkoords=[0 0 fixsz fixsz]; 
fixRect = CenterRectOnPointd(fixkoords, xCenter, yCenter);

%----------------------------------------------
%RUN MAIN EXPT
%----------------------------------------------
%set up the conditions
conds=[1:numel(hues) 1:numel(hues) 1:(numel(hues)-1)]; %run each colour 3 times, but cond 16 will be added to start in order to make sure that the first colour is easy and so we can ignore the very first RT
order=randperm(length(conds));
expt_conds = [numel(hues) conds(order)];

% Start Experiment
initString = 'Press <ANYKEY> to Begin Experiment';
Screen(window,'DrawText',initString,mainRect(3)/2-140,mainRect(4)/2,[255 255 255]);
Screen('Flip', window);
KbWait;
Screen(window,'FillRect',abTable.ppRGB(1,:));
Screen('Flip', window);

%grey adaptation
pause(6); %pause is sufficient as we're just showing a grey screen

% start presentation-loop
for j = 1:length(expt_conds)
    
         col_cond=expt_conds(j);
                 
        %%%%%%%%%%%%%%%%%
        %display stimuli
        %%%%%%%%%%%%%%%%%
 
    %Fixcross again
 Screen('FillRect', window, dark, fixRect);
 Screen('Flip',window);
WaitSecs(0.8);

%draw stimulus
 Screen('FillRect', window, values(col_cond,:), centeredRect);         
    Screen('Flip',window);

    %collect response
    [secs, key] = KbStrokeWait();
        
  key_name = KbName(key);

  fprintf('You pressed the "%s" key.\n', key_name);
       
%display grey page after stimulus    
    %Fixcross again
    Screen('FillRect',window, abTable.ppRGB(1,:));
	Screen('Flip', window);
        
    % write to result file
    fprintf(fid1,'%i\t %i\t %i\t %.5f\n',j,col_cond,key_name,secs);
    
end %end of trial presentation


% generate sound for acoustic feedback - at the end of blocks
y1=sin(0.5*[1:1024]);
sound([y1 y1 y1 y1])


%=====================
% end of experiment
%=====================
% close all files
fclose(fid1);

% Restore normal gamma table and close down:
RestoreCluts;
%graceful exit from PTB mode
Screen('Close',window);
Screen('CloseAll')
ShowCursor;

