function [AdjConditions]=PRPX_IsolCol_480_Lab(Colors,TrialsPerCon,MaxStd,Shift,varargin)
% function [AdjConditions]=PRPX_IsolCol_480_Lab(Colors,TrialsPerCon,MaxStd,Shift,varargin)
% -Colors: rows with R/G/B values (max 1). Colors will be adjusted to first row.
% -TrialsPerCon: Number of repetitions for each color
% -Shift: displacement of ellipse from center in pixel e.g [-300 0 +421]
% - optional (varargin)
%       - size in pixel [x y], eg. [360 540] is default
%
% -Assumes psychtoolbox is initiated and ProPixx attached
% -runs with 480 Hz
% -only works in Linux
% -when adjusting luminance (0-255), colors are transformed into CIE Lab space 
% and only the lightness value will be adjusted, leaving hue and chroma as is
% -colors with any starting luminance might be entered and can be scaled to the 
% (theoretical) maximum of 100 L (this however might bias hue and chroma)
% example call:
%   [AdjConditions]=PRPX_IsolCol_Lab([0.03 0.03 0.03; 1 0 0; 0 0 1],5,20,[0 -300]);
%
% for troubleshooting:
%   Colors = [0.2 0.2 0.2; 1 0 0; 0 0 1]; TrialsPerCon = 6;MaxStd = 15; Shift = [0 -300];
%   Colors = [0.2 0.2 0.2; 1 0 0]; TrialsPerCon = 6;MaxStd = 15; Shift = [0 -300];
%
% open points:_v2
%   - automatically start new line when result text does not fit to screen
%   - once in a while (yearly) check ProPixx color values to get correct transformations
%
% 2024  - return startkey to command prompt
% 2022 	- Norman Forschack, adapted from the RGB 480 Hz version

if nargin <4
    help PRPX_IsolCol_480_Lab
    return
end


if nargin <5
    p.stim_size = [360 540];
else
    p.stim_size = varargin{1}./2; % screen pixel number is reduced by 2 in each screen dimension
end
sca
%% initialization


% psychtoolbox start screen in black (instead of white)
Datapixx('Open');
Datapixx('SetPropixxDlpSequenceProgram', 2);
Datapixx('RegWrRd');
PsychDefaultSetup(2);
Screen('Preference', 'VisualDebugLevel', 1);


% get settings of screen
p.screen_num = max(Screen('Screens'));
p.screen = Screen('ConfigureDisplay', 'Scanout',p.screen_num, 0);

% set up window
[p.window, p.windowRect] = PsychImaging('OpenWindow', p.screen_num, Colors(1,:));
Screen('ColorRange', p.window,1,0); % restrict colors to range of 0 to 1
Screen('BlendFunction', p.window,  GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% Screen('BlendFunction', p.window,  GL_ONE, GL_ZERO); % no blending
[p.screenXpixels, p.screenYpixels] = Screen('WindowSize', p.window); % get window size
[p.xCenter, p.yCenter] = RectCenter(p.windowRect); % get center values of screen
Buttons = [KbName('Q') KbName('SPACE') KbName('n') KbName('m') KbName('RightShift')];
RestrictKeysForKbCheck(Buttons); % allow input from all buttons
[SECRETkey, SPACEkey, Nkey, Mkey, Startkey] = deal(...
    Buttons(1),Buttons(2),Buttons(3),Buttons(4), Buttons(5));
ListenChar(-1) % block button presses to matlab; window STRG + C to exit and ListenChar(0) at end


p.shift = [-p.xCenter/2, -p.yCenter/2; p.xCenter/2, -p.yCenter/2;... % shifts to four quadrants: upper left, upper right, lower left, lower right
    -p.xCenter/2, p.yCenter/2; p.xCenter/2, p.yCenter/2];

%% start presentation
% display start of isoluminance adjustment
% offscreen window
[p.offwin,p.offrect]=Screen('OpenOffscreenWindow',p.screen_num, [0 0 0 0], [0 0 p.screenXpixels/2 p.screenYpixels/2], [], [], []);
% get center of offscreen window
[p.xCenter_off, p.yCenter_off] = RectCenter(p.windowRect);
Screen('TextSize', p.offwin, 30);
% DrawFormattedText(p.offwin, 'Isoluminanzeinstellung', 'center', p.screenYpixels/2 * 0.4, [1 1 1]);
DrawFormattedText(p.offwin, 'Isoluminanzeinstellung','center', 'center', [1 1 1]);
for i_quad = 1:4 % shifst to quadrants
    newpos_stim(:,i_quad) = ...
        CenterRectOnPointd(p.offrect,p.xCenter_off+p.shift(i_quad,1),p.yCenter_off+p.shift(i_quad,2))';
end

key.keyisdown = 0;
key.keycode(Startkey)=0;
fprintf('\nPress %s to start isoluminance adjustments.\n',KbName(Startkey))
while ~key.keycode(Startkey) %~(key.keyisdown==1) && 
    [key.keyisdown,key.secs,key.keycode] = KbCheck(-1);
    Screen('DrawTextures', p.window, repmat(p.offwin,1,4),[], newpos_stim, [], [], [], []);
    Screen('Flip', p.window, 0);
end

% start isoluminance adjustment
ShAdj=numel(Shift); % shifts to adjust
LumAdj=zeros((size(Colors,1)-1)*ShAdj,1); % luminance values to adjust
LumAdjMed = LumAdj;
Pos2Pre=repmat(Shift',size(Colors,1)-1,1); % positions to present
Col2Pre = []; % create matrix with color values
for i_col = 1:size(Colors,1)-1
    Col2Pre(end+1:end+ShAdj,:)=repmat(Colors(i_col+1,:),ShAdj,1);
end

while any(LumAdj==0)
    disp(' ');
    Tr2Rep=find(LumAdj==0); % which luminance adjustments to do?
    TotTrials=numel(Tr2Rep)*TrialsPerCon; % number of total trials
    ConOrd=Tr2Rep(1+mod(randperm(TotTrials),numel(Tr2Rep))); % randomize trial sequence
    for n1=1:TotTrials
        fprintf('\b%d\n',mod(n1,10));
        TmpCon=ConOrd(n1);
        TmpPos=sum(ConOrd(1:n1)==ConOrd(n1));
        % disp([Pos2Pre(TmpCon,:) TmpCon Col2Pre(TmpCon,:) TmpPos]) % troubleshooting
        TmpLumAdj(TmpCon,TmpPos)=DoHFP(Colors(1,:),Col2Pre(TmpCon,:),Pos2Pre(TmpCon,:),p);
    end
    %LumAdj(1)=DoHFP(Colors(1,:),Colors(2,:));
    %LumAdj(2)=DoHFP(Colors(1,:),Colors(3,:));
    LumAdj(Tr2Rep)=round(mean(TmpLumAdj(Tr2Rep,:),2));
    LumAdjStd=std(TmpLumAdj(:,:),1,2);
    LumAdjMed(Tr2Rep)=median(TmpLumAdj(Tr2Rep,:),2);
    LumAdjAvg=mean(TmpLumAdj(:,:),2);
    
    % set up text to be displayed
    [p.offwin,p.offrect]=Screen('OpenOffscreenWindow',p.screen_num, [0 0 0 0], [0 0 p.screenXpixels/2 p.screenYpixels/2], [], [], []);
    % get center of offscreen window
    Screen('TextSize', p.offwin, 18);
    Text2Disp = 'Eingestellte Bedingungen:';
    for n1=1:size(Col2Pre,1)
        Text2Disp = [Text2Disp '\n\n' sprintf('col [%1.1f %1.1f %1.1f], pos [%4.0f]:',Col2Pre(n1,:),Pos2Pre(n1)),...
            '   ' sprintf(' %5.1f',TmpLumAdj(n1,:)) sprintf(': MEAN(STD) = %5.2f(%5.2f), MEDIAN = %5.2f',...
            LumAdjAvg(n1),LumAdjStd(n1),LumAdjMed(n1))];
    end
%     DrawFormattedText(p.offwin, Text2Disp, 'center', p.screenYpixels/2 * 0.2, [1 1 1]);
    [~,~,textbounds] = DrawFormattedText(p.offwin, Text2Disp, 'center', 'center', [1 1 1]);
    if (textbounds(1) < 1 || textbounds(3) > p.screenXpixels/2)...
            || (textbounds(2) < 1 || textbounds(4) > p.screenYpixels/2)
    end
    % display results
    if any(LumAdjStd>MaxStd)
        again = true;
        fprintf(1,['\n#############\nEinstellung muss wiederholt werden...\n' Text2Disp '\n#############\n'])
        fprintf(1,'\nODER den Geheimknopf druecken um mit den Median-Werten fortzufahren!\n')
    else
        again = false;
        fprintf(1,['\n#############\nSehr gut!\n' Text2Disp '\n#############\n'])
    end
    WaitSecs(1);
    key.keyisdown = 0;
    while ~(key.keyisdown==1) % i.e. takes any of the response active keys
        [key.keyisdown,key.secs,key.keycode] = KbCheck(-1);
        Screen('DrawTextures', p.window, repmat(p.offwin,1,4),[], newpos_stim, [], [], [], []);
        Screen('Flip', p.window, 0);
        if key.keycode(SECRETkey) && again
            % scale the median values
            LumAdj = round(LumAdjMed);
        elseif ~key.keycode(SECRETkey) && again
            LumAdj(LumAdjStd>MaxStd)=0; % set adjusted luminance values to 0 for values higher than cutoff, running luminance adjustment over again
        end
    end
end
AdjConditions=[Colors(1,:);LabScaleLuminance(Col2Pre(1:end,:),LumAdj)];
ListenChar(0)
try Screen('Close', p.window);
    Datapixx('close');
catch me, disp(me), 
end
end

% ========== Subfunctions ==============
function [LumAdj]=DoHFP(ColFix,ColAdj,PosAdj,p) % heterochromatic flicker presentation
Keys=[KbName('n') KbName('m') KbName('Space')]; % [decreases luminance, increases luminance, select luminance]

% ellipse parameters
%XRad=p.screenXpixels*0.1875; % width of ellipse
%YRad=p.screenYpixels*0.5; % height of ellipse
FreqDiv=round(p.screen.hz*4/15); % frequency of 15
%disp(sprintf('Adjusting isoluminance at %3.1f Hz',p.screen.hz*100/FreqDiv/100));
ovalRect = [0 0 p.stim_size]; % create rectangular shape of oval [x_center y_center width height]
ovalRect_PosAdj = CenterRectOnPointd(ovalRect,p.xCenter + PosAdj, p.yCenter);


% fixation cross parameters
crs.xCoords         = [-5 5 0 0];
crs.yCoords         = [0 0 -5 5];
crs.allCoords       = [crs.xCoords; crs.yCoords];

Screen('Flip', p.window, 0); % show background
key.keycode(Keys(3))=1; % set keypress to 0
LumAdj=floor(rand*2560)/10; % set starting luminance to random value
FrameCounter=0;
StepSize=0.05;
ActivityCount=0;
key.keycode_prev = key.keycode;
% start present1ation, stop when space bar is pressed
while (~key.keycode(Keys(3)) && ~key.keycode_prev(Keys(3))) || key.keycode_prev(Keys(3))
    % check for button presses
    key.keycode_prev = key.keycode;
    key.keycode(Keys(3))=0;
    [key.keyisdown,key.secs,key.keycode] = KbCheck(-1);
    
    if any(key.keycode(Keys(1:2))) % has increase or decrease button been pressed?
        LumAdj=max([LumAdj-key.keycode(Keys(1))*StepSize 0]); % adjust luminance
        LumAdj=min([LumAdj+key.keycode(Keys(2))*StepSize 255]); % adjust luminance
        %disp(LumAdj)
        ActivityCount=round(p.screen.hz/5); % map button presses to adjust step size ActivityCount=round(p.screen.hz/5);
        StepSize=min([StepSize+0.005 1]); % adjust step size of color changes StepSize=min([StepSize+1 8]);
    else
        ActivityCount=max([ActivityCount-1 0]); % map button presses to adjust step size
        if ActivityCount==0
            StepSize=0.05; % set step size to minimum value if button wasn't pressed for a long time StepSize=2;
        end
    end
    % scale luminance value of color acording to set luminance value
    NewCol=LabScaleLuminance(ColAdj,LumAdj);
    
    % draw ellipses
    for i_quad = 1:4
        FrameCounter=mod(FrameCounter+1,FreqDiv); % according to on/off frequency
        if FrameCounter<(FreqDiv/2)
            OvalCol = [NewCol(1),NewCol(2),NewCol(3)]; % color of on frame
        else
            OvalCol = [ColFix(1),ColFix(2),ColFix(3)]; % color of off frame
        end
        % quadshifted positions
        ovalRect_PosAdj_q = CenterRectOnPointd(ovalRect,p.xCenter+p.shift(i_quad,1), p.yCenter+p.shift(i_quad,2));
        
        Screen('FillOval', p.window, OvalCol, ovalRect_PosAdj_q) % actual drawing command
        
        % draw fixation cross
        Screen('DrawLines', p.window, crs.allCoords, 1, [0.8 0.8 0.8], [p.xCenter+p.shift(i_quad,1) p.yCenter+p.shift(i_quad,2)], 2);
    end
    
    % trouble shooting display
    %     Screen('TextSize', p.window, 20);
    %     Screen('TextFont', p.window, 'Courier');
    %     DrawFormattedText(p.window, ['\n\n\n\n' sprintf('%1.2f',StepSize) '\n' sprintf('%1.2f',LumAdj)],'center', 'center', [1 1 1]);
    
    Screen('Flip', p.window, 0); % show background
end

end

function [NewCol]=ScaleLuminance(Color,NewLum)
NewLum=NewLum(:);
NewCol=Color.*NewLum/255;
end

function [NewCol]=LabScaleLuminance(Color,NewLum)
% transforming luminance value to Lab lightness (0-100)
NewLum=100*NewLum(:)/255; 
% transforming Propixx colors to Lab colors
Color = xyz2lab(rgb2xyz_custom(Color,[0.665 0.321], [0.172 0.726], [0.163 0.039], [0.3127 0.3290 1-0.3127-0.3290]));
% replace lightness value with new Lab lightness value
Color(:,1) = NewLum;
% transform Lab colors back to Propixx color space
NewCol=xyz2rgb_custom(lab2xyz(Color),[0.665 0.321], [0.172 0.726], [0.163 0.039], [0.3127 0.3290 1-0.3127-0.3290]);
end
    