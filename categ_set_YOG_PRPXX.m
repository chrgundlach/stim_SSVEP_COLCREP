function categ_set_YOG_PRPXX(participantNumber,scr_param,RDK,p)

% Participants adjust the hue of a square in 3-degree steps
% to match one of four category labels: yellow, orange, lime, green.
%
% this is done at 4 levels of C
%
%inputs - participant number (as digit), scr_param can be either 'laptop'
%or 'propixx' and this determines colour transformations
%
% Output:
% One CSV file per category
%
% IMPORTANT:
% The included CIELCH -> sRGB conversion assumes a D65 white point
% and standard sRGB display characteristics. it is only for reality-check
% testing the stimuli on a laptop device prior to implementing in lab.
%
% written by J Martinovic, oct 2026, with AI assistance (chatgpt-6)

fclose('all');
close all;


%% ---------------- EXPERIMENT SETTINGS ----------------
if nargin < 4 || ~isfield(p,'isol')
R=[0.665 0.321]; G=[0.172 0.726]; B=[0.163 0.039]; %propix phosphors
WP=[0.3127 0.3290 1-0.3127-0.3290]; %D65

% Fixed CIELCH parameters
L_fixed = 63;       % CIELAB lightness, L
C_fixed = 60;       % CIELAB chroma, C, at maximum contrast level
Cmin=25; %minimum Chroma - should be sufficient for noticing colour
else
    R=p.isol.R; G=p.isol.G; B=p.isol.B; %propix phosphors
    WP=p.isol.WP; %D65

    % Fixed CIELCH parameters
    L_fixed = p.isol.L_fixed;       % CIELAB lightness, L
    C_fixed = p.isol.C_fixed;       % CIELAB chroma, C, at maximum contrast level
    Cmin    = p.isol.Cmin;
end

% Hue adjustment
hueStep = 3;        % Degrees per button press

% Trials
nCategories = 4;
nChromas=4;
trialsPerCategory = 6; %also per chroma

Chromas=logspace(log10(Cmin), log10(C_fixed), 4); %4 chromas
Chromasmatrix=repmat(Chromas,1,trialsPerCategory); %get all the chromas in a matrix 
Chromasmatrix=Chromasmatrix(randperm(length(Chromasmatrix))); %shuffle it for trial presentation

categories = {'yellow', 'orange', 'lime', 'green'};

% Output directory
outputDir = sprintf('%s%s',pwd,'/YOG/');   %'C:\\users\\jmartino\\';

%load isoluminance settings
file_name = ['indIsoCol_' num2str(participantNumber), '.mat'];
file_path = sprintf('%s%s%s',pwd,filesep,'IsoColors');
% data_table = readtable(fullfile(file_path, file_name));
load(fullfile(file_path, file_name),'indIsoCol')

%this file contains in its first column the colour name, in its second column the desired RGBs and in its 
% third coloumn the LAB values for each colour
isoLs = indIsoCol.isoLab(:,1); % extracting Ls
% Measured isoluminance settings
hue_measured = [101, 71, 131, 170];  % Hue angles in degrees (check if same in table)
% L_measured   = [50, 55, 48, 42];     % Example L* values 
L_measured = isoLs'; %JASNA - replace isoLs with code reflecting what Norman's script outputs...done (nf)

% Sort the measured hues in ascending order
[hue_measured, idx] = sort(hue_measured);
L_measured          = L_measured(idx);

% Extend the data to handle circular interpolation
hue_extended = [hue_measured(end)-360, ...
                hue_measured, ...
                hue_measured(1)+360];

L_extended = [L_measured(end), ...
              L_measured, ...
              L_measured(1)];

% Interpolate across the full CIELAB hue circle
hue_all = 0:359;

L_interpolated = interp1(hue_extended, L_extended, ...
                         hue_all, 'linear');

% Plot the measured and interpolated values
check_interp = true;
if check_interp
    figure;
    plot(hue_all, L_interpolated, 'b-', 'LineWidth', 1.5);
    hold on;
    scatter(hue_measured, L_measured, 70, 'r', 'filled');

    xlabel('Hue angle (degrees)');
    ylabel('Isoluminance L^*');
    title('Interpolated isoluminance settings in CIELAB');
    xlim([0 360]);
    xticks(0:30:360);
    grid on;
    legend('Interpolated L^*', 'Measured L^*', ...
        'Location', 'best');
end

%Set up colours

%let us choose a background level in CIE LCh
WP_LCh=[L_fixed, 0, 0]; 
%transform into LAB
abTable.Lab = lch2lab(WP_LCh);
%now into XYZ
abTable.XYZ = lab2xyz(abTable.Lab);
%now get RGB coordinates
backgroundColor = xyz2rgb_custom(abTable.XYZ,R,G,B,WP);

   % Square dimensions in pixels
%JASNA - TO DO - WE SHOULD DO THESE TASKS USING THE SMALL DOTS FROM EXPT
   % squareSize = 80;

%% ---------------- INITIALIZE PSYCHTOOLBOX ----------------
RefRate         = 120;
switch lower(scr_param)
    case 'laptop'
        AssertOpenGL;     %exit if obsolete version of PTB
        PsychDefaultSetup(2);
        KbName('UnifyKeyNames');
        whichScreen=max(Screen('Screens')); %select secondary display (if available)
        ScrWidth=900; ScrHeight=900;
        [window,windowRect]=Screen('OpenWindow',whichScreen,backgroundColor,[0,0,ScrWidth,ScrHeight]);
        [screenX, screenY] = RectCenter(windowRect);
        Screen('BlendFunction', window, ...
           GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    case 'propixx'
        % ProPixx setup
        ScrNum          = 1;
        ScrRes          = [1920 1080];
        PRPXres         = ScrRes;
        datapixxmode    = 0; % change here to 2 to run in 480Hz mode (but requires quadrant drawing or colors will be diluted!!!)
        onPRPX          = 1;
        Scr = struct('ScrNum',ScrNum,'RefRate',RefRate,'PRPXres',PRPXres,'BckGrCol',backgroundColor,'PRPXmode',datapixxmode);
        [~, windowRect, screenX, screenY, window, framerate, RespDev, keymap] = ...
            PTExpInit_GLSL(Scr,onPRPX);
end


% Key mappings
keyLeft  = KbName('LeftArrow');
keyRight = KbName('RightArrow');
keyEnter = KbName('SPACE');
keyEscape = KbName('ESCAPE');

    Screen('TextFont', window, 'Arial');
    Screen('TextSize', window, 28);
    FontCol = [1 1 1];

    
    % squareRect = CenterRectOnPointd([0 0 squareSize squareSize], ...
    %                                 screenX, screenY);
% initialize an RDK drawn in the periphery
if ~exist('RDK',"var")
    RDK = boot_RDK;
else
    RDK.RDK = RDK.RDK(1);
    RDK.RDK.freq  = 120;
    RDK.RDK.mov_speed = 0;
end
% RDKin.trial = struct('duration',1,...
%     'frames',RDK.RDK.freq,...
%     'cue',1);
% RDKin.trial.event = struct('onset',conmat.trials(trialindex(i_tr)).event_onset_frames,...
%     'direction',conmat.trials(trialindex(i_tr)).eventdirection,'RDK',conmat.trials(trialindex(i_tr)).eventRDK);
ps = struct('screensize', windowRect,'xCenter',screenX,'yCenter',screenY,'window',window, 'framerate', framerate, 'RespDev', RespDev, 'keymap',keymap);
RDKin.scr = ps;
RDKin.scr.refrate = RefRate;
RDKin.Propixx = 1;
RDKin.RDK = RDK;
Cross = Cross_init(screenX,screenY);
RDKin.crs = Cross;
RDKin.crs.size = Cross.crossLength;
RDKin.crs.cutout = 1;
RDKin.trial = 1;

[colmat,dotmat,dotsize,rdkidx,frames, lummat] = RDK_init_basic(RDKin.scr,RDKin.Propixx,RDKin.RDK,RDKin.trial,RDKin.crs);

%% ---------------- PREPARE TRIALS ----------------

% Randomize the order of the FOUR categories.
% All 10 trials for a category are completed consecutively.
categoryOrder = randperm(nCategories);

% Base starting hue for each category.
% Order corresponds to categories:
% yellow, orange, lime, green.
% baseHues = [101, 71, 131, 170];
baseHues = hue_measured;

% Count trials separately within each category.
categoryTrialNumber = zeros(1, nCategories);

% One data table per category.
dataTables = cell(1, nCategories);

for c = 1:nCategories
    dataTables{c} = table( ...
        strings(0,1), zeros(0,1), zeros(0,1), ...
        zeros(0,1), zeros(0,1), ...
        'VariableNames', ...
        {'Participant', 'Trial', 'Hue_deg', 'L', 'C'});
end

    %% ---------------- INSTRUCTIONS ----------------

    instructionText = [ ...
        'HUE SETTINGS TASK\n\n' ...
        'Adjust the square to match the best possible exemplar of the requested colour category.\n\n' ...
        'LEFT ARROW: move in one direction in hue space\n' ...
        'RIGHT ARROW: move in opposite direction\n\n' ...
                'To find the best example of the category for you, explore the hue regions on either\n' ...
                'side (LEFT/RIGHT) prior to tuning in to your final selection.\n\n' ...
                'SPACE: confirm your selection\n' ...
        'ESC: quit the experiment\n\n' ...
        'Press SPACE to begin.' ];

    DrawFormattedText(window, instructionText, ...
                      'center', 'center', FontCol);

    Screen('Flip', window);

    % Wait for Enter, or allow quitting.
    while true
        [keyDown, ~, keyCode] = KbCheck(RespDev);

        if keyDown
            if keyCode(keyEscape)
                sca;
                ListenChar(0);
                error('Experiment cancelled by participant.');    
            elseif keyCode(keyEnter)
                break;
            end
        end
    end

    KbReleaseWait;

 %% ---------------- MAIN EXPERIMENT ----------------

% Run categories in randomized order.
for block = 1:nCategories

    c = categoryOrder(block);
    categoryLabel = categories{c};

    % Complete all trials before moving to the next category.
    for trial = 1:trialsPerCategory*nChromas

        categoryTrialNumber(c) = categoryTrialNumber(c) + 1;
        thisTrial = categoryTrialNumber(c);

        % Initial hue = category-specific base hue + random offset.
        % Random integer offset between -10 and +10 degrees.
        hue = mod(baseHues(c) + randi([-10, 10]), 360);

        confirmed = false;

        while ~confirmed
            %determine chroma based on trial number
            C=Chromasmatrix(trial);

            if strcmp(scr_param,'propixx')
                colLCh=[L_interpolated(hue),C,hue];
                %transform into LAB
            colLab = lch2lab(colLCh);
            %now into XYZ
            colXYZ = lab2xyz(colLab);
                rgb = xyz2rgb_custom(colXYZ,R,G,B,WP);
            elseif strcmp(scr_param,'laptop')
            % Convert CIELCH to display RGB.
            [rgb, outOfGamut] = cielch_to_srgb( ...
                L_interpolated(hue), C, hue);
            rgb = 255 * rgb;
            end

            % Draw stimulus.
            Screen('FillRect', window, backgroundColor);
            % Screen('FillRect', window, rgb, squareRect);
            Screen('DrawDots', window, dotmat(:,:,1), dotsize(:,1), rgb, [screenX screenY], 0, 0);

            % Draw the concentric circle 
            % Screen('FrameOval', window, repmat(0.05,1,3), Cross.circleRect, Cross.circleThickness);
            % Screen('FillOval', window, repmat(0.05,1,3), Cross.circleRect); % filled
            Screen('DrawDots', window, [0 0],Cross.circleDiameter, repmat(0.05,1,3), [screenX screenY], 1, 0); % filled
            % draw cross
            Screen('DrawLines', window, Cross.allCoords, Cross.crossThickness, backgroundColor, [screenX, screenY], 2);
            % Draw the central dot (Filled)
            % Screen('FillOval', window, repmat(0.05,1,3), Cross.dotRect);
            Screen('DrawDots', window, [0 0],Cross.dotDiameter, repmat(0.05,1,3), [screenX screenY], 1, 0);

            %JASNA - REMOVE PRINTING OF HUE ON SCREEN PRIOR TO TESTING
            taskText = sprintf( ...
                ['Match this category: %s\n\n' ...
                 'LEFT / RIGHT: adjust hue counterclockwise or clockwise\n' ...
                 'SPACE: confirm selection\n\n' ...
                 'Hue: %.0f degrees'], ...
                 categoryLabel, hue);

            DrawFormattedText(window, taskText, ...
                'center', screenY + RDK.RDK.size(2)/2 + 35, ...
                FontCol);

            Screen('Flip', window);

            % Read keyboard.
            [keyDown, ~, keyCode] = KbCheck(RespDev);

            if keyDown

                if keyCode(keyEscape)
                    sca;
                    ListenChar(0);
                    error('Experiment cancelled by participant.');
                elseif keyCode(keyLeft)
                    hue = mod(hue - hueStep, 360);
                    KbReleaseWait;

                elseif keyCode(keyRight)
                    hue = mod(hue + hueStep, 360);
                    KbReleaseWait;

                elseif keyCode(keyEnter)
                    confirmed = true;
                    KbReleaseWait;
                end

            end

        end

        %% Save response

        newRow = table( ...
            string(participantNumber), thisTrial, hue, ...
            L_interpolated, C, ...
            'VariableNames', ...
            {'Participant', 'Trial', 'Hue_deg', 'L', 'C'});

        dataTables{c} = [dataTables{c}; newRow];

        outputFile = fullfile(outputDir, ...
            sprintf('%s_%s.csv', ...
            num2str(participantNumber), categoryLabel));

        % Update the category file after every response.
        writetable(dataTables{c}, outputFile);

        % Brief inter-trial interval.
        Screen('FillRect', window, backgroundColor);
        DrawFormattedText(window, 'Response recorded.', ...
            'center', 'center', FontCol);
        Screen('Flip', window);

        WaitSecs(0.4);

    end

end


    %% ---------------- END EXPERIMENT ----------------

    Screen('FillRect', window, backgroundColor);

    DrawFormattedText(window, ...
        'Experiment complete. Thank you!', ...
        'center', 'center', FontCol);

    Screen('Flip', window);
    WaitSecs(2);

    sca;
    ShowCursor;
    ListenChar(0);

    fprintf('\nExperiment complete.\n');
    fprintf('Data saved to: %s\n', outputDir);

    % generate sound for acoustic feedback - at the end of expt
y1=sin(0.5*[1:1024]);
sound([y1 y1 y1 y1])

end

%% =========================================================
%  LOCAL FUNCTION: CIELCH -> sRGB
% ==========================================================

function [rgb, outOfGamut] = cielch_to_srgb(L, C, h)

    % Convert CIELCH to CIELAB.
    a = C * cosd(h);
    b = C * sind(h);

    % CIELAB -> XYZ, D65 reference white.
    Xn = 0.95047;
    Yn = 1.00000;
    Zn = 1.08883;

    delta = 6/29;

    fx = (L + 16)/116 + a/500;
    fy = (L + 16)/116;
    fz = (L + 16)/116 - b/200;

    invf = @(t) (t > delta) .* (t.^3) + ...
                (t <= delta) .* (3 * delta^2 .* (t - 4/29));

    X = Xn * invf(fx);
    Y = Yn * invf(fy);
    Z = Zn * invf(fz);

    % XYZ -> linear sRGB (D65).
    M = [ 3.2404542, -1.5371385, -0.4985314; ...
         -0.9692660,  1.8760108,  0.0415560; ...
          0.0556434, -0.2040259,  1.0572252 ];

    linearRGB = M * [X; Y; Z];

    % Check whether the colour is outside the sRGB gamut.
    outOfGamut = any(linearRGB < 0 | linearRGB > 1);

    % Clip out-of-gamut values.
    linearRGB = min(max(linearRGB, 0), 1);

    % Apply the sRGB gamma transfer function.
    rgb = zeros(3,1);

    idx = linearRGB <= 0.0031308;

    rgb(idx) = 12.92 * linearRGB(idx);

    rgb(~idx) = 1.055 * linearRGB(~idx).^(1/2.4) - 0.055;

    rgb = min(max(rgb, 0), 1);
    rgb = rgb(:)';

end

function Lab = lch2lab(LCh)

% Convert CIELCH to CIELAB.
    a = LCh(2) * cosd(LCh(3));
    b = LCh(2) * sind(LCh(3));
    Lab = [LCh(1) a b];
end

function [RDK] = boot_RDK % most of the options are not needed here for main experiment, however the function for dot position calculation needs it
RDK.RDK(1).size             = [150 250];                % width and height of RDK in pixel; only even values 
RDK.RDK(1).centershift      = [-151 0];                 % position of RDK center; x and y deviation from center in pixel [-x 0] = left
RDK.RDK(1).col              = [1 0 0 1; 0 0 0 0];       % default color will be overwritten during categ_set_YOG_PRPXX call
RDK.RDK(1).col_label        = 'rot';                    % label of RDK color
RDK.RDK(1).freq             = 120;                      % flicker frequency, frequency of a full "on"-"off"-cycle
RDK.RDK(1).mov_freq         = 120;                      % Defines how frequently the dot position is updated; 0 will adjust the update-frequency to your flicker frequency (i.e. dot position will be updated with every "on"-and every "off"-frame); 120 will update the position for every frame for 120Hz or for every 1. quadrant for 480Hz 
RDK.RDK(1).num              = 85;                       % number of dots % 85
RDK.RDK(1).mov_speed        = 0;                        % movement speed in pixel
RDK.RDK(1).mov_dir          = [0 1; 0 -1; -1 0; 1 0];   % movement direction  [0 1; 0 -1; -1 0; 1 0] = up, down, left, right
RDK.RDK(1).dot_size         = 12;
RDK.RDK(1).shape            = 1; 

RDK.event.type              = 'globalmotion';               % event type global motion
RDK.event.duration          = 12;                           % time of coherent motion
RDK.event.coherence         = .6;                           % percentage of coherently moving dots 0.4
RDK.event.direction         = RDK.RDK(1).mov_dir;           % movement directions for events
end

function cross = Cross_init(rectX,rectY)
    cross.crossLength = 24;            % Total length of the hair-cross lines in pixels
    cross.crossThickness = 4;          % Thin cross lines
    cross.circleDiameter = 24;         % Diameter of the concentric circle
    cross.circleThickness = 2;         % Line thickness of the circle
    cross.dotDiameter = 5;             % Microscopic central dot anchor
    
    % =========================================================================
    % DEFINE GEOMETRY
    % =========================================================================
    % 1. Cross Lines
    xLines = [-cross.crossLength/2, cross.crossLength/2, 0, 0];
    yLines = [0, 0, -cross.crossLength/2, cross.crossLength/2];
    cross.allCoords = [xLines; yLines];
    
    % 2. Concentric Circle Bounding Box
    cross.circleRect = [rectX - cross.circleDiameter/2, rectY - cross.circleDiameter/2, ...
                  rectX + cross.circleDiameter/2, rectY + cross.circleDiameter/2];
              
    % 3. Central Dot Bounding Box
    cross.dotRect = [rectX - cross.dotDiameter/2, rectY - cross.dotDiameter/2, ...
               rectX + cross.dotDiameter/2, rectY + cross.dotDiameter/2];
end