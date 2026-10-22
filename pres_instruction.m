function [] = pres_instruction(p,ps,RDK,blocknum,randmat,con_flag, key)
%PRES_INSTRUCTION present instructions
%   p           = parameters
%   ps          = screen parameters

%% initial parameters
INST.flag =                 {'training';'experiment'};
INST.side =                 {'linke';'rechte'};

% with pre-cue task
% INST.text{1} =              [...                % text for training
%     sprintf('TRAINING - block %1.0f',blocknum)...
%     '\n\n\nBitte fixieren Sie kontinuierlich das Fixationskreuz!'...
%     '\n\nReagieren Sie sobald einer der Balken des Kreuzes kürzer wird'...
%     '\nmit einem Druck auf die Leertaste.'...
%     '\n\nSobald das Fixationskreuz die Farbe ändert, achten Sie auf die'...
%     '\nangezeigten Punktewolken. Wenn sich ein Teil der beachteten'...
%     '\nPunkte kurz kohärent in eine Richtung bewegt, drücken Sie'...
%     '\ndie Leertaste. Seien Sie dabei so schnell wie möglich.'...
%     sprintf('\n\nNutzen Sie für die Antworten die %s Hand.', randmat.mats.responsehand{find(randmat.mats.block==1,1,'first')})
%     ];
% INST.text{2} =              [...                % text for experiment
%     sprintf('EXPERIMENT - Block %1.0f von %1.0f',blocknum,p.stim.blocknum)...
%     '\n\n\nBitte fixieren Sie kontinuierlich das Fixationskreuz!'...
%     '\n\nReagieren Sie sobald einer der Balken des Kreuzes kürzer wird'...
%     '\nmit einem Druck auf die Leertaste.'...
%     '\n\nSobald das Fixationskreuz die Farbe ändert, achten Sie auf die'...
%     '\nangezeigten Punktewolken. Wenn sich ein Teil der beachteten'...
%     '\nPunkte kurz kohärent in eine Richtung bewegt, drücken Sie'...
%     '\ndie Leertaste. Seien Sie dabei so schnell wie möglich.'...
%     sprintf('\n\nNutzen Sie für die Antworten die %s Hand.', randmat.mats.responsehand{find(randmat.mats.block==blocknum,1,'first')})
%     ];

% without pre-cue task

INST.text{1} =              [...                % text for training
    sprintf('TRAINING - block %1.0f',blocknum)...
    '\n\n\nBitte fixieren Sie kontinuierlich das Fixationskreuz!\n\n' ...
    sprintf('Achten Sie auf die Punkte der Farbe %s.\n\n',RDK.RDK(randmat.trials(1).RDK2attend).col_label)...
    'Wenn sich ein Teil der beachteten'...
    '\nPunkte kurz kohärent in eine Richtung bewegt, drücken Sie die Leertaste.'...
    '\nSeien Sie dabei so schnell wie möglich.' ...
    sprintf('\n\nNutzen Sie für die Antworten die %s Hand.', randmat.mats.responsehand{find(randmat.mats.block==1,1,'first')})
    ];
if con_flag == 2
    INST.text{2} =              [...                % text for experiment
        sprintf('EXPERIMENT - Block %1.0f von %1.0f',blocknum,p.stim.blocknum)...
        '\n\n\nBitte fixieren Sie kontinuierlich das Fixationskreuz!\n\n'...
        sprintf('Achten Sie auf die Punkte der Farbe %s.\n\n',RDK.RDK(randmat.trials(blocknum).RDK2attend).col_label) ...
        'Wenn sich ein Teil der beachteten'...
        '\nPunkte kurz kohärent in eine Richtung bewegt, drücken Sie die Leertaste.'...
        '\nSeien Sie dabei so schnell wie möglich.' ...
        sprintf('\n\nNutzen Sie für die Antworten die %s Hand.', randmat.mats.responsehand{find(randmat.mats.block==blocknum,1,'first')})
        ];
end


% position of fixation cross
% INST.crs.xCoords =          [-p.crs_dims(1) p.crs_dims(1) 0 0];
% INST.crs.yCoords =          [0 0 -p.crs_dims(2) p.crs_dims(2)];
% INST.crs.allCoords =        [INST.crs.xCoords; INST.crs.yCoords];
% INST.crs.offset =           [0 180; 0 280]; % [x y] offset of cue cross

% pixels for shift into 4 quadrants
quadshift = [p.scr_res(1)*(1/4) p.scr_res(2)*(1/4); p.scr_res(1)*(3/4) p.scr_res(2)*(1/4); ...
    p.scr_res(1)*(1/4) p.scr_res(2)*(3/4); p.scr_res(1)*(3/4) p.scr_res(2)*(3/4)];


%% present text in quadrants
% draw text and stimuli (before shifting to the quadrants)
% offscreen window
[ps.offwin,ps.offrect]=Screen('OpenOffscreenWindow',p.scr_num, [0 0 0 0], [0 0 p.scr_res(1)/2 p.scr_res(2)/2], [], [], []);
% get center of offscreen window
[ps.xCenter_off, ps.yCenter_off] = RectCenter(ps.offrect);

% draw instruction text
Screen('TextSize', ps.offwin, 14);
% DrawFormattedText(tx.instruct, INST.text{1}, tx.xCenter_off, p.scr_res(1)/2 * 0.1, p.stim_color);
DrawFormattedText(ps.offwin, INST.text{con_flag}, 'center', p.scr_res(1)/2 * 0.1, p.crs.color);

% draw text, how to start trial
DrawFormattedText(ps.offwin, 'Mit LEERTASTE geht es los!', 'center', p.scr_res(2)/2 * 0.85, p.crs.color);


for i_quad = 1:4 % shifst to quadrants
    newpos_stim(:,i_quad) = ...
        CenterRectOnPointd(ps.offrect,quadshift(i_quad,1),quadshift(i_quad,2))';
end

% show info outside
if con_flag == 2
    col2attend = RDK.RDK(randmat.trials(blocknum).RDK2attend).col_label;
else
    col2attend = RDK.RDK(randmat.trials(1).RDK2attend).col_label;
end
fprintf('\nVersuchsperson startet %s Block %1.0f mit Leertaste. Relevante Farbe: %s...', INST.flag{con_flag},blocknum,col2attend)

% [key.pressed, key.firstPress]=KbQueueCheck;
key.rkey=key.SPACE;
[key.keyisdown,key.secs,key.keycode] = KbCheck; 
while ~(key.keycode(key.rkey)==1)                       % continuously present feedback (wait for q)
    [key.keyisdown,key.secs,key.keycode] = KbCheck;
    % draw text
    Screen('DrawTextures', ps.window, repmat(ps.offwin,1,4),[], newpos_stim, [], [], [], []);
    Screen('Flip', ps.window, 0);                   % flip screen
end
try Screen('Close', ps.offwin); end



%% alert before experiment starts
[ps.offwin,ps.offrect]=Screen('OpenOffscreenWindow',p.scr_num, [0 0 0 0], [0 0 p.scr_res(1)/2 p.scr_res(2)/2], [], [], []);
% get center of offscreen window
[ps.xCenter_off, ps.yCenter_off] = RectCenter(ps.offrect);

% draw instruction text
Screen('TextSize', ps.offwin, 14);
DrawFormattedText(ps.offwin, 'Gleich geht es los.','center','center', p.crs.color);
for i_quad = 1:4 % shifst to quadrants
    newpos_stim(:,i_quad) = ...
        CenterRectOnPointd(ps.offrect,quadshift(i_quad,1),quadshift(i_quad,2))';
end
Screen('DrawTextures', ps.window, repmat(ps.offwin,1,4),[], newpos_stim, [], [], [], []);
Screen('Flip', ps.window, 0);
fprintf('Block beginnt!\n')
t=WaitSecs(2);
try Screen('Close', ps.offwin); end

end

