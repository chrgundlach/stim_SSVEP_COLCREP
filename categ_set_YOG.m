function categ_set_YOG(participantNumber,scr_param)

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
R=[0.665 0.321]; G=[0.172 0.726]; B=[0.163 0.039]; %propix phosphors
WP=[0.3127 0.3290]; %D65

% Fixed CIELCH parameters
L_fixed = 70;       % CIELAB lightness, L
C_fixed = 50;       % CIELAB chroma, C, at maximum contrast level
Cmin=20; %minimum Chroma - should be sufficient for noticing colour

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
outputDir = 'C:\\users\\jmartino\\';

%load isoluminance settings
        filename=[ participantNumber, '_isolum.csv'];
        data_table = readtable(fullfile(file_path, filename));    
%this file contains in its first column the colour name, in its second column the desired RGBs and in its 
% third coloumn the LAB values for each colour
isoLs=data_table.Lab;
% Measured isoluminance settings
hue_measured = [101, 131, 71, 311];  % Hue angles in degrees
L_measured   = [50, 55, 48, 42];     % Example L* values 
%JASNA - replace isoLs with code reflecting what Norman's script outputs

% Sort the measured hues in ascending order
[hue_measured, idx] = sort(hue_measured);
L_measured = L_measured(idx);

%% Extend the data to handle circular interpolation
hue_extended = [hue_measured(end)-360, ...
                hue_measured, ...
                hue_measured(1)+360];

L_extended = [L_measured(end), ...
              L_measured, ...
              L_measured(1)];

%% Interpolate across the full CIELAB hue circle
hue_all = 0:359;

L_interpolated = interp1(hue_extended, L_extended, ...
                         hue_all, 'linear');

%% Plot the measured and interpolated values
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
   squareSize = 80;

%% ---------------- INITIALIZE PSYCHTOOLBOX ----------------
AssertOpenGL;     %exit if obsolete version of PTB

PsychDefaultSetup(2);
KbName('UnifyKeyNames');

% Key mappings
keyLeft  = KbName('LeftArrow');
keyRight = KbName('RightArrow');
keyEnter = KbName('Return');
keyEscape = KbName('ESCAPE');

%open display
%define screen and stimulus configuration parameters
whichScreen=max(Screen('Screens')); %select secondary display (if available)
if strcmp('laptop',scr_param) %for piloting
    ScrWidth=900; ScrHeight=900;
[window,windowRect]=Screen('OpenWindow',whichScreen,backgroundColor,[0,0,ScrWidth,ScrHeight]);
elseif strcmp('propixx,scr_param') %for real
[window,windowRect]=Screen('OpenWindow',whichScreen);
end

    Screen('BlendFunction', window, ...
           GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    Screen('TextFont', window, 'Arial');
    Screen('TextSize', window, 28);

    [screenX, screenY] = RectCenter(windowRect);
    squareRect = CenterRectOnPointd([0 0 squareSize squareSize], ...
                                    screenX, screenY);

%% ---------------- PREPARE TRIALS ----------------

% Randomize the order of the FOUR categories.
% All 10 trials for a category are completed consecutively.
categoryOrder = randperm(nCategories);

% Base starting hue for each category.
% Order corresponds to categories:
% yellow, orange, lime, green.
baseHues = [101, 71, 131, 170];

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
                'ENTER: confirm your selection\n' ...
        'ESC: quit the experiment\n\n' ...
        'Press ENTER to begin.' ];

    DrawFormattedText(window, instructionText, ...
                      'center', 'center', [255 255 255]);

    Screen('Flip', window);

    % Wait for Enter, or allow quitting.
    while true
        [keyDown, ~, keyCode] = KbCheck;

        if keyDown
            if keyCode(keyEscape)
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
            Screen('FillRect', window, rgb, squareRect);

            %JASNA - REMOVE PRINTING OF HUE ON SCREEN PRIOR TO TESTING
            taskText = sprintf( ...
                ['Match this category: %s\n\n' ...
                 'LEFT / RIGHT: adjust hue counterclockwise or clockwise\n' ...
                 'ENTER: confirm selection\n\n' ...
                 'Hue: %.0f degrees'], ...
                 categoryLabel, hue);

            DrawFormattedText(window, taskText, ...
                'center', screenY + squareSize/2 + 35, ...
                [255 255 255]);

            Screen('Flip', window);

            % Read keyboard.
            [keyDown, ~, keyCode] = KbCheck;

            if keyDown

                if keyCode(keyEscape)
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
            L_interpolated(hue), C, ...
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
            'center', 'center', [255 255 255]);
        Screen('Flip', window);

        WaitSecs(0.4);

    end

end


    %% ---------------- END EXPERIMENT ----------------

    Screen('FillRect', window, backgroundColor);

    DrawFormattedText(window, ...
        'Experiment complete. Thank you!', ...
        'center', 'center', [255 255 255]);

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
