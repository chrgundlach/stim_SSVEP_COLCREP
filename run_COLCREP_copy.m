function [RDK] = run_COLCREP(sub,flag_training, flag_isolum, flag_block)
% run_COLCREP(sub,flag_training, flag_isolum, flag_block)
%   runs experiment SSVEP_COLCREP
%       sub:            participant number
%       flag_training:  1 = do training
%       flag_isolum:    1 = do isoluminance adjustment
%       flag_block:     1 = start with block 1
%           e.g. run_FShiftPrime1of2(99,1,1,1)
%
% experiment to Modelling CRFs inside and outside the focus of spatial attention as a 
% challenge to the narrow inhibitory zone account of Stormer &amp; Alvarez

% open questions/to do:
% - 

% changed
%  - p.stim.RDK2attend
% - p.stim.hue_levels
% - p.stim.blocknum 


% Christopher Gundlach, Jasna Martionovic, Norman Forschack, Leipzig, 2026

if nargin < 4
    help run_COLCREP
    return
end

%% parameters
% sub = 1; flag_training = 1; flag_block = 1; flag_isolum = 1;
% design
p.sub                   = sub;                  % subject number
p.flag_block            = flag_block;           % block number to start
p.flag_training         = flag_training;        % do training

p.blink_intervallength  = [1000];               % interval length for blinks
p.blink_interval        = [5];                  % blinks every x intervals of contrast steps
p.targ_respwin          = [201, 1000];          % time window for responses in ms [200 1200]

% screen
p.scr_num               = 1;                    % screen number
% p.scr_num               = 2;                    % screen number [for trouble shooting]
p.scr_res               = [1920 1080];          % resolution
p.scr_refrate           = 480;                  % refresh rate in Hz (e.g. 85)
p.scr_color             = [0.316 0.316 0.316 1];   % default: [0.05 0.05 0.05 1]; ; color of screen [R G B Alpha]
p.scr_imgmultipl        = 4;

% some isoluminace parameters
p.isol.TrlAdj           = 5;                    % number of trials used for isoluminance adjustment
p.isol.MaxStd           = 5;                   % standard deviation tolerated
p.isol.run              = false;                % isoluminance run?
p.isol.override         = [];                   % manually set colors for RDK1 to RDKXs e.g. []
p.isol.override         = repmat([0.0980 0.0392 0 1; 0 0.0596 0.1490 1],2,1); % these are the ones used for p.isol.bckgr = p.scr_color(1:3);

% p.isol.bckgr            = p.scr_color(1:3)+0.2;          % isoluminant to background or different color?
p.isol.bckgr            = p.scr_color;          % isoluminant to background or different color?

 % plot_colorwheel( [0.0980 0.0392 0; 0 0.0596 0.1490;0 0.0745 0],'ColorSpace','propixxrgb','LAB_L',50,'NumSegments',60,'AlphaColWheel',1,'LumBackground',100, 'disp_LAB_vals', 1)


% stimplan
p.stim.side2attend      = [1];            % which sides need to be attended? 1 = center; 2 = periphery; fixed per stimulation block
p.stim.RDK2attend       = [2;3];            % which RDK needs to be attended; [RDK attended con 1; RDK attended con 2] for [side attended 1, side attended 2]
                                            %  [1 2] = left; [3 4] = right [so far attended color is fixed for participant]
% p.stim.contr_level_cons = { ...             % contrast sweep levels for [RDK1 to RDK4] by conditions 1 = lowest; n = highest; orthogonal to p.stim.side2attend
%     {4 4 4 4;                               % RDK on attended side of attended color
%     1 2 3 4;                                % RDK on attended side of unattended color
%     4 4 4 4;                                % RDK on unattended side of attended color
%     1 2 3 4};                               % RDK on unattended side of unattended color          
%     {1 2 3 4;
%     4 4 4 4;
%     1 2 3 4;
%     4 4 4 4}};
% change of distractor color in periphery only
p.stim.contr_level_cons = { ...             % contrast sweep levels for [RDK1 to RDK4] by conditions 1 = lowest; n = highest; orthogonal to p.stim.side2attend
    {1 2 3 4;                               % RDK on unattended side (periphery) of attended and neighboring colors
     4 4 4 4;                               % RDK on attended side (center) of unattended color
     4 4 4 4;}};                            % RDK on attended side (center) of attended color
% % change of target color on both sides only
% p.stim.contr_level_cons = { ...             % contrast sweep levels for [RDK1 to RDK4] by conditions 1 = lowest; n = highest; orthogonal to p.stim.side2attend
%     {1 2 3 4;                               % RDK on attended side of attended color
%     4 4 4 4;                                % RDK on attended side of unattended color
%     1 2 3 4;                                % RDK on unattended side of attended color
%     4 4 4 4}};
p.stim.hue_levels = [1 2 3 4];                % different hue levels [left of base hue, base hue, right of base hue]
t.allNumbers = cell2mat([p.stim.contr_level_cons{:}]);
p.stim.unique_contrasts =unique(t.allNumbers);
p.stim.condition        = numel(p.stim.side2attend)*size(p.stim.RDK2attend,1)*sum(cellfun('size' ,p.stim.contr_level_cons,2))*numel(p.stim.hue_levels);
p.stim.contr_intervalllength = 1000;        % interval length of how long each contrast is shown in ms

p.stim.contr_repeats_per_block = 12;        % number of up and down sweeps per stimulation block
p.stim.blocknum         = 48;               % number of blocks with series of contrast sweeps
p.stim.eventnum         = 10;               % number of events per block

p.stim.event.type       = 2;                % types of events (1 = targets only, 2 = targets + distrators)
p.stim.event.ratio      = [1 1];            % ratio of events vs distractors
p.stim.event.length     = 0.3;              % lengt of events in s
p.stim.event.min_onset  = 0.2;              % time before event onset in each block in s 
p.stim.event.min_offset = 0;                % min offset from target end to end of trial in s
p.stim.event.min_dist   = 0.8;              % min time between events in s


% stimuli
% positions as in Gundlach et al., 2023: RDK 9.4*9.4 with 4.8 distance between ERP_visualangle(200, 120, [1920 1080]/2, [63.5 36])
% RDK1 = left color 1; RDK2 = left color 2; RDK3 = right color 1; RDK4 = right color 2; 
RDK.RDK(1).size             = [150 250];                % width and height of RDK in pixel; only even values 
RDK.RDK(1).centershift      = [-150 0];                 % position of RDK center; x and y deviation from center in pixel [-x 0] = left
RDK.RDK(1).col              = [1 0 0 1; p.scr_color(1:3) 0];% "on" and "off" color
RDK.RDK(1).col_label        = 'gelb';                    % label of RDK color
RDK.RDK(1).freq             = 14;                       % flicker frequency, frequency of a full "on"-"off"-cycle
RDK.RDK(1).mov_freq         = 120;                      % Defines how frequently the dot position is updated; 0 will adjust the update-frequency to your flicker frequency (i.e. dot position will be updated with every "on"-and every "off"-frame); 120 will update the position for every frame for 120Hz or for every 1. quadrant for 480Hz 
RDK.RDK(1).num              = 85;                       % number of dots % 85
RDK.RDK(1).mov_speed        = 1;                        % movement speed in pixel
RDK.RDK(1).mov_dir          = [0 1; 0 -1; -1 0; 1 0];   % movement direction  [0 1; 0 -1; -1 0; 1 0] = up, down, left, right
RDK.RDK(1).dot_size         = 12;
RDK.RDK(1).shape            = 1;                        % 1 = square RDK; 0 = ellipse/circle RDK;
 
RDK.RDK(2).size             = RDK.RDK(1).size;                
RDK.RDK(2).centershift      = [0 0];                  
RDK.RDK(2).col              = [0 0.4 1 1; p.scr_color(1:3) 0];
RDK.RDK(2).col_label        = 'blau';                    % label of RDK color
RDK.RDK(2).freq             = 20;
RDK.RDK(2).mov_freq         = RDK.RDK(1).mov_freq;
RDK.RDK(2).num              = RDK.RDK(1).num;
RDK.RDK(2).mov_speed        = RDK.RDK(1).mov_speed;
RDK.RDK(2).mov_dir          = RDK.RDK(1).mov_dir;
RDK.RDK(2).dot_size         = RDK.RDK(1).dot_size;
RDK.RDK(2).shape            = RDK.RDK(1).shape;          

RDK.RDK(3).size             = RDK.RDK(1).size;              
RDK.RDK(3).centershift      = [0 0];                   
RDK.RDK(3).col              = RDK.RDK(1).col;
RDK.RDK(3).col_label        = 'gelb';
RDK.RDK(3).freq             = 17;
RDK.RDK(3).mov_freq         = RDK.RDK(1).mov_freq;
RDK.RDK(3).num              = RDK.RDK(1).num;
RDK.RDK(3).mov_speed        = RDK.RDK(1).mov_speed;
RDK.RDK(3).mov_dir          = RDK.RDK(1).mov_dir;
RDK.RDK(3).dot_size         = RDK.RDK(1).dot_size;
RDK.RDK(3).shape            = RDK.RDK(1).shape;

% RDK.RDK(4).size             = RDK.RDK(1).size;              
% RDK.RDK(4).centershift      = RDK.RDK(3).centershift;                   
% RDK.RDK(4).col              = RDK.RDK(2).col;
% RDK.RDK(4).col_label        = RDK.RDK(2).col_label;
% RDK.RDK(4).freq             = 23;
% RDK.RDK(4).mov_freq         = RDK.RDK(1).mov_freq;
% RDK.RDK(4).num              = RDK.RDK(1).num;
% RDK.RDK(4).mov_speed        = RDK.RDK(1).mov_speed;
% RDK.RDK(4).mov_dir          = RDK.RDK(1).mov_dir;
% RDK.RDK(4).dot_size         = RDK.RDK(1).dot_size;
% RDK.RDK(4).shape            = RDK.RDK(1).shape;

RDK.event.type              = 'globalmotion';               % event type global motion
RDK.event.duration          = p.stim.event.length;          % time of coherent motion
RDK.event.coherence         = .6;                           % percentage of coherently moving dots 0.4
RDK.event.direction         = RDK.RDK(1).mov_dir;           % movement directions for events

% fixation cross
p.crs.color                 = [0.4 0.4 0.4 1];    % color of fixation cross [0.5 0.5 0.5 1];
% p.crs.color                 = [1 1 1 1];        % for Stimulation Demo Video!
p.crs.dims                  = [12];             % dimension of fixation cross
p.crs.width                 = 2;                % width of fixation cross
p.crs.cutout                = 1;                % 1 = no dots close to fixation cross

% trigger
p.trig.rec_start        = 253;                  % trigger to start recording
p.trig.rec_stop         = 254;                  % trigger to stop recording
p.trig.tr_start         = 77;                   % trial start; main experiment
p.trig.tr_stop          = 99;                   % trial end; main experiment
p.trig.tr_cued_side     = [100 200];            % cue type: [RDK1 RDK2] % not used any longer
p.trig.tr_cued_RDK      = [100 200];            % cue type: [RDK2 RDK3]
p.trig.tr_contr_type    = 10*(1:numel(numel(p.stim.contr_level_cons))); % contrast type
p.trig.tr_contr_level   = p.stim.unique_contrasts; % contrast levels [old not used]
p.trig.tr_hue           = p.stim.hue_levels; % contrast levels 
p.trig.button           = 60;                   % button press
p.trig.event_type       = [71 72];              % target distractor
p.trig.blink            = [66];                 % trigger when blink window starts


% logfiles
p.log.path              = '/home/stimulation120/matlab/user/christopher/stim_SSVEP_COLCREP/logfiles/';
p.log.exp_name          = 'SSVEP_COLCREP';
p.log.add               = '_a';


%% check for logfile being present
filecheck=dir(sprintf('%sVP%02.0f_timing*',p.log.path,p.sub));
if ~isempty(filecheck)
    reply = input(sprintf('\nVP%02.0f existiert bereits. Datei überschreiben? [j/n]... ',p.sub),'s');
    if strcmp(reply,'j')
        p.filename = sprintf('VP%02.0f_timing',p.sub);
    else
        [temp name_ind]=max(cellfun(@(x) numel(x), {filecheck.name}));
        p.filename = sprintf('%s%s',filecheck(name_ind).name(1:end-4),p.log.add);
    end
else
    p.filename = sprintf('VP%02.0f_timing',p.sub);
end

t.isol = {};
% routine to check for older isoluminance adjustments
for i_file = 1:numel(filecheck)
    t.in = load(fullfile(filecheck(i_file).folder,filecheck(i_file).name));
    t.datenum{i_file} = filecheck(i_file).datenum;
    t.isol{i_file} = t.in.p.isol;

    % load responses
    resp = t.in.resp;
    
end



%% Screen init
ps.input = struct('ScrNum',p.scr_num,'RefRate',p.scr_refrate,'PRPXres',p.scr_res,'BckGrCol',p.scr_color,'PRPXmode',2);
[~, ps.screensize, ps.xCenter, ps.yCenter, ps.window, ps.framerate, ps.RespDev, ps.keymap] = PTExpInit_GLSL(ps.input,1);

% % for testing outside of lab
% ps.input = struct('ScrNum',2,'RefRate',60,'PRPXres',p.scr_res,'BckGrCol',p.scr_color,'PRPXmode',0);
% [~, ps.screensize, ps.xCenter, ps.yCenter, ps.window, ps.framerate, ps.RespDev, ps.keymap] = PTExpInit_GLSL_adj(ps.input,0);

% some initial calculations
% fixation cross
ps.center = [ps.xCenter ps.yCenter];
p.crs.half = p.crs.dims/2;
p.crs.bars = [-p.crs.half p.crs.half 0 0; 0 0 -p.crs.half p.crs.half];
% p.crs.bars = [-p.crs.half p.crs.half p.crs.half -p.crs.half; -p.crs.half p.crs.half -p.crs.half p.crs.half];
p.crs.bars_blink = [-p.crs.half p.crs.half -p.crs.half p.crs.half -p.crs.half -p.crs.half p.crs.half p.crs.half; ...
    -p.crs.half -p.crs.half p.crs.half p.crs.half -p.crs.half p.crs.half -p.crs.half p.crs.half];
% p.crs.bars_blink = 

% shift into 4 quadrants (running with 480 Hz)
ps.shift = [-ps.xCenter/2, -ps.yCenter/2; ps.xCenter/2, -ps.yCenter/2;... % shifts to four quadrants: upper left, upper right, lower left, lower right
    -ps.xCenter/2, ps.yCenter/2; ps.xCenter/2, ps.yCenter/2];

p.crs.lines = {};
% regular cross
t.lines = [];
for i_quad=1:p.scr_imgmultipl
    t.lines = cat(2, t.lines, [p.crs.bars(1,:)+ps.shift(i_quad,1); p.crs.bars(2,:)+ps.shift(i_quad,2)]); %array with start and end points for the fixation cross lines, for all four quadrants
end
p.crs.lines{1} =t.lines;
% blink cross cross
t.lines = [];
for i_quad=1:p.scr_imgmultipl
    t.lines = cat(2, t.lines, [p.crs.bars_blink(1,:)+ps.shift(i_quad,1); p.crs.bars_blink(2,:)+ps.shift(i_quad,2)]); %array with start and end points for the fixation cross lines, for all four quadrants
end
p.crs.lines{2} =t.lines;



%% keyboard and ports setup ???
KbName('UnifyKeyNames')
Buttons = [KbName('ESCAPE') KbName('Q') KbName('SPACE') KbName('j') KbName('n')  KbName('1!') KbName('2@') KbName('3#')];
RestrictKeysForKbCheck(Buttons);
key.keymap=false(1,256);
key.keymap(Buttons) = true;
key.keymap_ind = find(key.keymap);
[key.ESC, key.SECRET, key.SPACE, key.YES, key.NO] = deal(...
    Buttons(1),Buttons(2),Buttons(3),Buttons(4),Buttons(5));

%% start experiment
% initialize randomization of  RDK colors [RDK1 and RDK2 task relevant RDK3 and RDK4 not]
rng(p.sub,'v4')
[RDK.RDK(:).col_init] = deal(RDK.RDK(:).col);
% t.idx = randperm(2); t.idx = [t.idx t.idx+2]; % split
t.idx = randperm(2); t.idx = t.idx+1; % central vs periphery
[RDK.RDK([2 3]).col] = deal(RDK.RDK(t.idx).col);
[RDK.RDK([2 3]).col_label] = deal(RDK.RDK(t.idx).col_label);
p.isol.override = p.isol.override(t.idx,:);

% initialize blank variables
% timing = []; button_presses = []; resp = []; randmat = [];
timing = []; button_presses = []; randmat = [];


%% initial training
if p.flag_training
    fprintf(1,'\nTraing starten mit q')
    inp.prompt_check = 0;
    while inp.prompt_check == 0             % loop to check for correct input
        [key.keyisdown,key.secs,key.keycode] = KbCheck;
        if key.keycode(key.SECRET)==1
            flag_trainend = 0; inp.prompt_check = 1;
        end
        Screen('Flip', ps.window, 0);
    end
    
    
    i_bl = 1;
    flag_trainend = 0;
    while flag_trainend == 0 % do training until ended
        rng(p.sub*100+i_bl,'v4')
        randmat.training{i_bl} = rand_COLCREP(p, RDK,  1);
        pres_instruction(p,ps,RDK,i_bl,randmat.training{i_bl},1,key); % Instruktion fürs Training
        [timing.training{i_bl},button_presses.training{i_bl},resp.training{i_bl}] = ...
            pres_COLCREP(p, ps, key, RDK, randmat.training{i_bl}, i_bl,1);
        save(sprintf('%s%s',p.log.path,p.filename),'timing','button_presses','resp','randmat','p', 'RDK')
        pres_feedback(resp.training{i_bl},p,ps, key,RDK)
               
        % loop for training to be repeated
        fprintf(1,'\nTraing wiederholen? (j/n)')
        inp.prompt_check = 0;
        while inp.prompt_check == 0             % loop to check for correct input
            [key.keyisdown,key.secs,key.keycode] = KbCheck; 
            if key.keycode(key.YES)==1
                i_bl = i_bl + 1; flag_trainend = 0; inp.prompt_check = 1;
            elseif key.keycode(key.NO)==1
                flag_trainend = 1; inp.prompt_check = 1;
            end
            Screen('Flip', ps.window, 0);
        end  
        
    end
end

%% then isoluminance adjustment
% do the heterochromatic flicker photometry
if flag_isolum == 1
%     
%     PsychDefaultSetup(2);
%     Datapixx('Open');
%     Datapixx('SetPropixxDlpSequenceProgram', 0);
%     Datapixx('RegWrRd');
     
    % initial colors
    % ColorNavigator % (with hues:[101, 71, 131, 170, 301]'; %  with high chroma=60, lightness=63 (0.316 grey): :  yellow, green, lime, green, blue
    % selectedColors = abTableSelecCol(:,1:6);
    % selectedColors.Properties.VariableNames{1,1} = 'names';
    % selectedColors.names = {'yellow'; 'orange'; 'lime'; 'green'; 'blue'};
    % selectedIsogray = selectedColors(1,:);
    % selectedIsogray.names = 'isogray';
    % [selectedIsogray.goalLCh(1,1:3), selectedIsogray.goalLab(1,1:3)] = deal([selectedColors.goalLab(1,1) 0 0]);
    % selectedIsogray.goalPpRGB = grayColor; 
    % [selectedIsogray.hueAngle selectedIsogray.goalLCh(3)] = deal(nan); 
    % selectedIsogray.goalStdRGB = xyz2rgb(lab2xyz(selectedIsogray.goalLab(1:3)));
    % save('selectedColors_CIELAB63Gray60Chroma_20261015.mat','selectedColors','selectedIsogray')
    % load color preselection
    load('selectedColors_CIELAB63Gray60Chroma_20261015.mat','selectedColors')
    % p.isol.init_cols = cell2mat({RDK.RDK.col}'); p.isol.init_cols = p.isol.init_cols(1:2:end,1:3);
    p.isol.init_cols = [selectedColors.goalPpRGB([1 5],:);...
        selectedColors.goalPpRGB(1:4,:)];
    
    % start isoluminance script only RGB output (no alpha)
    % [Col2Use] = PRPX_IsolCol_480_Lab(...
    %     [p.isol.bckgr(1:3); p.isol.init_cols(:,1:3)],...
    %     p.isol.TrlAdj,...
    %     p.isol.MaxStd,...
    %     cellfun(@(x) x(1), {RDK.RDK.centershift})',...
    %     RDK.RDK(1).size);
    [Col2Use] = PRPX_IsolCol_480_Lab(...
        [p.isol.bckgr(1:3); p.isol.init_cols(:,1:3)],...
        p.isol.TrlAdj,...
        p.isol.MaxStd,...
        0,...
        RDK.RDK(1).size);
    
    for i_RDK = 1:numel(RDK.RDK)
        RDK.RDK(i_RDK).col(1,:) = [Col2Use(1+i_RDK,:) 1];
    end
    % index function execution
    p.isol.run = sprintf('originally run: %s',datestr(now));
    p.isol.coladj = [Col2Use(2:end,:) ones(size(Col2Use,1)-1,1)];
    save(sprintf('%s%s',p.log.path,p.filename),'timing','button_presses','resp','randmat','p', 'RDK')
    
    fprintf('\nadjusted colors:\n')
    for i_col = 1:size(p.isol.coladj,1)
        fprintf('RDK%1.0f [%1.4f %1.4f %1.4f %1.4f]\n', i_col,p.isol.coladj(i_col,:))
    end
    
    Screen('CloseAll')
    Datapixx('SetPropixxDlpSequenceProgram', 0);
    Datapixx('RegWrRd');
    Datapixx('close');
else
    % select colors differently
    fprintf(1,'\nKeine Isoluminanzeinstellung. Wie soll verfahren werden?')
    % specify options
    % option1: use default values
    isol.opt(1).available = true;
    t.cols = cell2mat({RDK.RDK(:).col}');
    isol.opt(1).colors = t.cols(1:2:end,:);
    isol.opt(1).text = sprintf('default: [%1.2f %1.2f %1.2f %1.2f] [%1.2f %1.2f %1.2f %1.2f] [%1.2f %1.2f %1.2f %1.2f]',isol.opt(1).colors');
    % option2: use isoluminance values of previously saved dataset
    if ~isempty(t.isol) % file loaded 
        [t.t t.idx] = max(cell2mat(t.datenum));
        if any(strcmp(fieldnames(t.isol{t.idx}),'coladj')) % and adjusted colors exist?s
            isol.opt(2).available = true;
            isol.opt(2).colors = t.isol{t.idx}.coladj(1:end,:);
            isol.opt(2).text = sprintf('aus gespeicherter Datei: %s',sprintf('[%1.2f %1.2f %1.2f] ',isol.opt(2).colors(:,1:3)'));
        else
            isol.opt(2).available = false;
            isol.opt(2).colors = [];
            isol.opt(2).text = [];
        end
    else
        isol.opt(2).available = false;
        isol.opt(2).colors = [];
        isol.opt(2).text = [];
    end
    % option3: use manual override
    if ~isempty(p.isol.override)
        isol.opt(3).available = true;
        isol.opt(3).colors = p.isol.override;
        isol.opt(3).text = sprintf('manuell definiert in p.isol override: [%1.2f %1.2f %1.2f %1.2f] [%1.2f %1.2f %1.2f %1.2f] [%1.2f %1.2f %1.2f %1.2f] [%1.2f %1.2f %1.2f %1.2f]',isol.opt(3).colors');
    else
        isol.opt(3).available = false;
        isol.opt(3).colors = [];
        isol.opt(3).text = [];
    end
    % check for buttons
    IsoButtons = Buttons(6:8);
    isol.prompt.idx = find([isol.opt(:).available]);
    t.prompt = [];
    for i_prompt = 1:numel(isol.prompt.idx)
        t.prompt = [t.prompt sprintf('\n(%1.0f) %s',i_prompt,isol.opt(isol.prompt.idx(i_prompt)).text)];
    end
    
    % display options
    fprintf('%s',t.prompt)
    inp.prompt_check = 0;
    while inp.prompt_check == 0             % loop to check for correct input
        [key.keyisdown,key.secs,key.keycode] = KbCheck;
        if any(key.keycode(IsoButtons))
            inp.prompt_check = 1;
        end
        Screen('Flip', ps.window, 0);
    end
    Col2Use = isol.opt(isol.prompt.idx(key.keycode(IsoButtons(1:numel(isol.prompt.idx)))==1)).colors;
    % use selected colors
    for i_RDK = 1:numel(RDK.RDK)
        RDK.RDK(i_RDK).col(1,:) = Col2Use(i_RDK,:);
    end
    % index function execution
    switch isol.prompt.idx(key.keycode(IsoButtons(1:numel(isol.prompt.idx)))==1)
        case 1
            p.isol.run = sprintf('default at %s',datestr(now));
        case 2
            p.isol.run = sprintf('reloaded at %s from %s',datestr(now),datestr(t.datenum{t.idx}));
        case 3
            p.isol.run = sprintf('override at %s',datestr(now));
    end
    p.isol.coladj = Col2Use;
%     save(sprintf('%s%s',p.log.path,p.filename),'timing','button_presses','resp','randmat','p', 'RDK')
    
    fprintf('\nselected colors:\n')
    for i_col = 1:size(p.isol.coladj,1)
        fprintf('RDK%1.0f [%1.4f %1.4f %1.4f]\n', i_col,p.isol.coladj(i_col,:))
    end
end

%% redo initialization
ps.input = struct('ScrNum',p.scr_num,'RefRate',p.scr_refrate,'PRPXres',p.scr_res,'BckGrCol',p.scr_color,'PRPXmode',2);
[~, ps.screensize, ps.xCenter, ps.yCenter, ps.window, ps.framerate, ps.RespDev, ps.keymap] = PTExpInit_GLSL(ps.input,1);

% keyboard setup
KbName('UnifyKeyNames')
Buttons = [KbName('ESCAPE') KbName('Q') KbName('SPACE') KbName('j') KbName('n') KbName('1!') KbName('2@') KbName('3#')];
RestrictKeysForKbCheck(Buttons);
key.keymap=false(1,256);
key.keymap(Buttons) = true;
key.keymap_ind = find(key.keymap);
[key.ESC, key.SECRET, key.SPACE, key.YES, key.NO] = deal(...
    Buttons(1),Buttons(2),Buttons(3),Buttons(4),Buttons(5));


%% do training again?
% loop for training to be repeated
fprintf(1,'\nTraing starten (j/n)')
inp.prompt_check = 0;
while inp.prompt_check == 0             % loop to check for correct input
    [key.keyisdown,key.secs,key.keycode] = KbCheck;
    if key.keycode(key.YES)==1
        flag_trainend = 0; inp.prompt_check = 1;
    elseif key.keycode(key.NO)==1
        flag_trainend = 1; inp.prompt_check = 1;
    end
    Screen('Flip', ps.window, 0);
end

if ~exist('i_bl'); i_bl = 1; end
while flag_trainend == 0 % do training until ended
    rng(p.sub*100+i_bl,'v4')
    randmat.training{i_bl} = rand_COLCREP(p, RDK,  1);
    pres_instruction(p,ps,RDK,i_bl,randmat.training{i_bl},1,key); % Instruktion fürs Training
    [timing.training{i_bl},button_presses.training{i_bl},resp.training{i_bl}] = ...
        pres_COLCREP(p, ps, key, RDK, randmat.training{i_bl}, i_bl,1);
    save(sprintf('%s%s',p.log.path,p.filename),'timing','button_presses','resp','randmat','p', 'RDK')
    pres_feedback(resp.training{i_bl},p,ps, key,RDK)
    
    % loop for training to be repeated
    fprintf(1,'\nTraing wiederholen? (j/n)')
    inp.prompt_check = 0;
    while inp.prompt_check == 0             % loop to check for correct input
        [key.keyisdown,key.secs,key.keycode] = KbCheck;
        if key.keycode(key.YES)==1
            i_bl = i_bl + 1; flag_trainend = 0; inp.prompt_check = 1;
        elseif key.keycode(key.NO)==1
            flag_trainend = 1; inp.prompt_check = 1;
        end
        Screen('Flip', ps.window, 0);
    end
    
end


%% present each block
% randomization
rng(p.sub,'v4')                                 % allow for same randomization of randmat
randmat.experiment = rand_COLCREP(p, RDK,  0);    % randomization
for i_bl = p.flag_block:p.stim.blocknum
    % instruction before each block
    pres_instruction(p,ps,RDK,i_bl,randmat.experiment,2,key); % Instruktion fürs Experiment
    % start experiment
    [timing.experiment{i_bl},button_presses.experiment{i_bl},resp.experiment{i_bl}] = ...
        pres_COLCREP(p, ps, key, RDK, randmat.experiment, i_bl,0);
    % save logfiles
    save(sprintf('%s%s',p.log.path,p.filename),'timing','button_presses','resp','randmat','p', 'RDK')
          
    pres_feedback(resp.experiment{i_bl},p,ps, key, RDK)    
end

fprintf(1,'\n\nENDE\n')

%Close everything
Datapixx('SetPropixxDlpSequenceProgram', 0);
Datapixx('RegWrRd');
Datapixx('close');
ppdev_mex('Close', 1);
ListenChar(0);
sca;


end

