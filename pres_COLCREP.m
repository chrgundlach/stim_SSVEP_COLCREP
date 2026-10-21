function [timing,key,resp] = pres_COLCREP(p, ps, key, RDK, conmat, blocknum, flag_training)
% presents experiment SSVEP_COLCREP
%   p               = parameters
%   ps              = screen parameters
%   RDK             = RDK parameters
%   blocknum        = number of block
%   flag_training   = flag for trainig (1) or experiment (0)

%% adaptations for training
if flag_training == 1
    blocknum_present = blocknum;
    blocknum = 1;
end

%% prepare datapixx output
bufferAddress = 8e6;
% % samplesPerTrigger = 1;
triggersPerRefresh = 1; % send one per refresh (i.e. p.scr_refrate at 480 Hz)


%% initialize some RDK settings
% define input for RDK init function
RDKin.scr = ps; RDKin.scr.refrate = p.scr_refrate;
RDKin.Propixx = p.scr_imgmultipl;
RDKin.RDK = RDK;
RDKin.crs = p.crs;
RDKin.crs.size = RDKin.crs.dims;

%% loop for each trial
trialindex = find(conmat.mats.block==blocknum);

% send start trigger
if flag_training~=1
    PRPX_sendRecTrigger('start')
end

% Wait for release of all keys on keyboard, then sync us to retrace:
KbWait(ps.RespDev,1); % wait for releasing keys on indicated response device

% create keayboard queue
KbQueueCreate(ps.RespDev)

if flag_training~=1
    fprintf(1,'\nexperiment block %1.0f - Praesentation - Trial:', blocknum)
else
    fprintf(1,'\ntraining block %1.0f - Praesentation - Trial:', blocknum_present)
end
ttt=WaitSecs(0.3);
crttime = GetSecs;

% loop across trials
for i_tr = 1:numel(trialindex) % trial sequences (roughly 1 min)
    fprintf('%1.0f',mod(i_tr,10))
    inittime=GetSecs;
    %% initialize trial structure, RDK, cross, logs
    RDKin.trial = struct('duration',conmat.trials(trialindex(i_tr)).triallength_times,...
        'frames',conmat.trials(trialindex(i_tr)).triallength_frames,...
        'cue',1);
    RDKin.trial.event = struct('onset',conmat.trials(trialindex(i_tr)).event_onset_frames,...
        'direction',conmat.trials(trialindex(i_tr)).eventdirection,'RDK',conmat.trials(trialindex(i_tr)).eventRDK);
    fprintf('\nInitialisiere trial...')
    [colmat,dotmat,dotsize,rdkidx,frames, lummat] = RDK_init_COLCREP(RDKin.scr,RDKin.Propixx,RDKin.RDK,RDKin.trial,RDKin.crs);
    fprintf('done!\n')

    %%%%%% this needs to be adapted to display colors correctly according to plan
    % first create an addtional contrastmat for all dots in each frame that can then be used to alter the colors
    t.contrmat = reshape(permute(repmat( ...
        conmat.trials(trialindex(i_tr)).contrast_values', ...
        [1,1,p.scr_refrate/p.scr_imgmultipl]), [1 3 2]),numel(RDKin.RDK.RDK),[]);
    contrastmat = nan(size(rdkidx));
    for i_rdk = 1:numel(RDKin.RDK.RDK)
        contrastmat(rdkidx(:,1)==i_rdk,:) = repmat(t.contrmat(i_rdk,:),sum(rdkidx(:,1)==i_rdk),1);
    end
    % figure; plot(t.mat')
    % we can now use the contrastmat to scale the colmat
    % here all RGB values are however scaled...I gues it is not what we wanted
    contrastmat_scaled = (contrastmat+1)./(max(contrastmat(:))+1);
    colmat_scaled = colmat;
    colmat_scaled(1:3,:,:) = colmat(1:3,:,:).*permute(repmat(contrastmat_scaled,[1,1,3]),[3 1 2]); % don't scale alpha value
    %%%%%%
    
    % initialize fixation cross
    % which cross?
    crossmat = ones(1,size(colmat,3)); % by default show normal fixation cross
    
    % display blink cross
    for i_blink = find(~isnan(conmat.trials(trialindex(i_tr)).blink_windows))
        t.idx = (1:(p.scr_refrate/p.scr_imgmultipl*p.stim.contr_intervalllength/1000))-1 + ...
            ((conmat.trials(trialindex(i_tr)).contrast_window_onsetframes(i_blink)-1)/p.scr_imgmultipl)+1;
        crossmat(t.idx) = 2;
    end
    

    % color
    colmat_cr = repmat(p.crs.color' ,[1 1 size(colmat,3)]);
    % preallocate timing
    timing(i_tr) = struct('VBLTimestamp',NaN(1,frames.flips),'StimulusOnsetTime',NaN(1,frames.flips),...
        'FlipTimestamp',NaN(1,frames.flips),'Missed',NaN(1,frames.flips));
    
    %% set up responses
    %setup key presses
    key.presses{i_tr}=nan(size(colmat,3),sum(key.keymap));
    key.presses_t{i_tr}=nan(size(colmat,3),sum(key.keymap));
    
    resp(i_tr).trialnumber              = trialindex(i_tr);
    resp(i_tr).blocknumber              = conmat.trials(trialindex(i_tr)).block;
    resp(i_tr).side_attended            = conmat.trials(trialindex(i_tr)).side2attend;
    resp(i_tr).RDK_attended             = conmat.trials(trialindex(i_tr)).RDK2attend;
    resp(i_tr).contrast_con             = conmat.trials(trialindex(i_tr)).contrast_con;
    resp(i_tr).contrast_values          = conmat.trials(trialindex(i_tr)).contrast_values;
    resp(i_tr).contrast_levels          = conmat.trials(trialindex(i_tr)).contrast_levels;
    resp(i_tr).contrast_window_onsetframes = conmat.trials(trialindex(i_tr)).contrast_window_onsetframes;
    resp(i_tr).contrast_window_onsettimes = conmat.trials(trialindex(i_tr)).contrast_window_onsettimes;
    resp(i_tr).col_attended             = {RDK.RDK(conmat.trials(trialindex(i_tr)).RDK2attend).col_label};
    resp(i_tr).freq_attended            = [RDK.RDK(conmat.trials(trialindex(i_tr)).RDK2attend).freq];
    resp(i_tr).triallength_times        = conmat.trials(trialindex(i_tr)).triallength_times;
    resp(i_tr).triallength_frames       = conmat.trials(trialindex(i_tr)).triallength_frames;
    resp(i_tr).eventnum                 = conmat.trials(trialindex(i_tr)).eventnum;
    resp(i_tr).eventtype                = conmat.trials(trialindex(i_tr)).eventtype; % 1 = target; 2 = distractor
    resp(i_tr).eventRDK                 = conmat.trials(trialindex(i_tr)).eventRDK;
    resp(i_tr).eventdirection           = conmat.trials(trialindex(i_tr)).eventdirection;
    resp(i_tr).event_onset_frames       = conmat.trials(trialindex(i_tr)).event_onset_frames;
    resp(i_tr).event_onset_times        = conmat.trials(trialindex(i_tr)).event_onset_times;
    resp(i_tr).eventwindow              = conmat.trials(trialindex(i_tr)).eventwindow;
    resp(i_tr).blink_windows            = conmat.trials(trialindex(i_tr)).blink_windows;
    resp(i_tr).block                    = conmat.trials(trialindex(i_tr)).block;
    resp(i_tr).responsehand             = conmat.trials(trialindex(i_tr)).responsehand;
           
    %% set up datapixx trigger vector
    % prepare datapixx scheduler
    % trigger signal needs to encompass first frame after stimulation has ended to send trial stop trigger
    if size(colmat,3)*p.scr_imgmultipl>...
            conmat.trials(trialindex(i_tr)).triallength_frames+1
        doutWave = zeros(1,size(colmat,3)*p.scr_imgmultipl); % each entry corresponds to a trigger
    else
        doutWave = zeros(1,size(colmat,3)*p.scr_imgmultipl+p.scr_imgmultipl); % each entry corresponds to a trigger
    end
    
    % write trigger numbers into doutwave
    % trial start trigger
    doutWave(1) = p.trig.tr_start;
    % trial end trigger (presented at first frame after stimulation)
    doutWave(size(colmat,3)*p.scr_imgmultipl+1) = p.trig.tr_stop;
    
    % condition trigger accoding to chroma contrast type and level and attended side
    for i_window = 2:size(resp(i_tr).contrast_levels,1)
        doutWave(resp(i_tr).contrast_window_onsetframes(i_window)) = ...
            p.trig.tr_cued_side(resp(i_tr).side_attended) + ... % which side to attend
            p.trig.tr_contr_type(resp(i_tr).contrast_con) + ... % which contrast type
            p.trig.tr_contr_level(resp(i_tr).contrast_levels(i_window)); % which contrast level within the respective type
    end
    
    % add trigger for blinks
    for i_blink = find(~isnan(resp.blink_windows))
        doutWave(resp(i_tr).contrast_window_onsetframes(i_blink)) = p.trig.blink;
    end
    
    % event trigger
    for i_ev = 1:resp(i_tr).eventnum
        t.trigger = p.trig.event_type(resp(i_tr).eventtype(i_ev));
        doutWave(resp(i_tr).event_onset_frames(i_ev)) = t.trigger;
    end
    doutWave = [doutWave;zeros(triggersPerRefresh-1,numel(doutWave))]; doutWave=doutWave(:);
    samplesPerFlip = triggersPerRefresh * p.scr_imgmultipl;
    % figure; plot(doutWave)
    % doutWave(doutWave>0)
    
    %% getting wait ITI time and then start drawing routines
    % wait
    if i_tr > 1
        crttime2 = GetSecs;
        t.timetowait = (p.ITI(1)/1000)-(crttime2 - crttime);
        ttt=WaitSecs(t.timetowait);
        % troubleshooting
        %fprintf('\nbefore wait = %1.3f; after wait = %1.3f\n',crttime2 - crttime, GetSecs - crttime)
    end
    
    % draw fixation cross
    Screen('DrawLines', ps.window, p.crs.lines{1}, p.crs.width, p.crs.color, ps.center, 0);
    
    % send 0 before again to reset everything
    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    
    % write outsignal
    Datapixx('WriteDoutBuffer', doutWave, bufferAddress);
    % disp(Datapixx('GetDoutStatus'));
    Datapixx('SetDoutSchedule', 0, [samplesPerFlip, 2], numel(doutWave), bufferAddress); % 0 - scheduleOnset delay, [samplesPerFlip, 2] - sheduleRate in samples/video frame, framesPerTrial - maxSheduleFrames
    Datapixx('StartDoutSchedule');
    
    %% keyboard
    % start listening to keyboard
    KbQueueStart(ps.RespDev);
    KbQueueFlush(ps.RespDev);
    
    % flip to get everything synced
    Screen('Flip', ps.window, 0);
    
    %% Stimulation Demo Video Part1/3

    % movie = Screen('CreateMovie',ps.window, 'Prime.mov', p.scr_res(1)/2, p.scr_res(2)/2, 120, ':CodecSettings=Videoquality=0.5 Profile=2'); %
    % Default Settings
    % movie = Screen('CreateMovie',ps.window, sprintf('PrimeVid%d.mov', movieIndex), p.scr_res(1)/2, p.scr_res(2)/2, 120, ':CodecSettings=Videoquality=0.5 Profile=2'); % Try defaults first
    % movieIndex = movieIndex +1;
    %% loop across trials   
    for i_fl = 1:frames.flips
        %% Drawing
        % RDK
        % Screen('DrawDots', ps.window, dotmat(:,:,i_fl), dotsize(:,i_fl), colmat(:,:,i_fl), ps.center, 0, 0);
        Screen('DrawDots', ps.window, dotmat(:,:,i_fl), dotsize(:,i_fl), colmat_scaled(:,:,i_fl), ps.center, 0, 0);
        % fixation cross
        Screen('DrawLines', ps.window, p.crs.lines{crossmat(i_fl)}, p.crs.width, p.crs.color, ps.center, 0);
        
        %% start trigger schedule and start listening to response device
        if i_fl == 1 % send the trigger with the start of the 1st flip
            Datapixx('RegWrVideoSync');
        end
        
        % Flip
        [timing(i_tr).VBLTimestamp(i_fl), timing(i_tr).StimulusOnsetTime(i_fl), timing(i_tr).FlipTimestamp(i_fl), timing(i_tr).Missed(i_fl)] = Screen('Flip', ps.window, 0);
        
        % send trigger/save timing/ reset timing
        if i_fl == 1
            % start trigger
            starttime=GetSecs;
            KbEventFlush(ps.RespDev); % flush keyboard
        end
        
        %% check for button presses
        [key.pressed, key.firstPress]=KbQueueCheck(ps.RespDev);
        key.presses{i_tr}(i_fl,:)=key.firstPress(key.keymap)>1;
        key.presses_t{i_tr}(i_fl,:)=(key.firstPress(key.keymap)-starttime).*key.presses{i_tr}(i_fl,:);
        if any(key.firstPress(key.keymap)>1)
            lptwrite(1,find(key.firstPress(key.keymap),1,'first'),500);
        end
        %% Stimulation Demo Video Part 2/3 - Adding Frames
        % Screen('AddFrameToMovie', ps.window);
    end
        %% Stimulation Demo Video Part 3/3 - Finalizing the Video
        % Screen('FinalizeMovie', movie);
    %% ITI
    % draw fixation cross again
    Screen('DrawLines', ps.window, p.crs.lines{1}, p.crs.width, p.crs.color, ps.center, 0);
    
    % flip
    Screen('Flip', ps.window, 0);
    
    % get time
    crttime = GetSecs;
    
    % add waiting period to check for late button presses
    ttt=WaitSecs(p.targ_respwin(2)/1000-p.stim.event.min_offset-p.stim.event.length);
    
    % check for button presses
    [key.pressed, key.firstPress]=KbQueueCheck(ps.RespDev);
    key.presses{i_tr}(i_fl+1,:)=key.firstPress(key.keymap)>1;
    key.presses_t{i_tr}(i_fl+1,:)=(key.firstPress(key.keymap)-starttime).*key.presses{i_tr}(i_fl+1,:);
    
    
    
    
    %%%%%%%%
    % do behavioral calculation
    key.presses{i_tr}(1,:)=[];
    key.presses_t{i_tr}(1,:)=[];
    
    % get frame and timing of button press onsets
    resp(i_tr).button_presses_fr=nan(max(sum(key.presses{i_tr})),size(key.presses{i_tr},2));
    resp(i_tr).button_presses_t=resp(i_tr).button_presses_fr;
    resp(i_tr).button_presses_t_rel2cue=resp(i_tr).button_presses_fr;
    for i_bt = 1:size(key.presses{i_tr},2)
        try
            resp(i_tr).button_presses_fr(1:sum(key.presses{i_tr}(:,i_bt)),i_bt)=...
                find(key.presses{i_tr}(:,i_bt));
            resp(i_tr).button_presses_t(1:sum(key.presses{i_tr}(:,i_bt)),i_bt)=...
                key.presses_t{i_tr}(find(key.presses{i_tr}(:,i_bt)),i_bt)*1000; % in ms
            % relative to cue
            resp(i_tr).button_presses_t_rel2cue(1:sum(key.presses{i_tr}(:,i_bt)),i_bt)=...
                key.presses_t{i_tr}(find(key.presses{i_tr}(:,i_bt)),i_bt)*1000 -...
                resp(i_tr).pre_cue_times*1000; % in ms
        catch
            resp(i_tr).button_presses_fr(:,i_bt)=nan;
        end
    end

    % all relevant presses 
    t.presses = resp(i_tr).button_presses_t(:,key.keymap_ind==key.SPACE);
   

    % main events
    % check for hits {'hit','miss','CR','FA_proper','FA'}
    resp(i_tr).button_presses_type = {}; %{'hit','miss','CR','FA_proper','FA'}
    resp(i_tr).button_presses_RT = []; % reaction time in ms (after event or closest to other event)
    resp(i_tr).event_response_type = {}; %{'hit','miss','CR','FA_proper'}
    resp(i_tr).event_response_RT = []; %reaction time or nan
    % all relevant presses 
    t.presses = resp(i_tr).button_presses_t(:,key.keymap_ind==key.SPACE);
    
    % first define response windows
    if any(~isnan(resp(i_tr).eventtype))
        t.respwin = (resp(i_tr).event_onset_times(~isnan(resp(i_tr).eventtype))+(p.targ_respwin/1000))*1000;
    end
    % loop across button presses
    for i_press = 1:numel(t.presses)
        if any(~isnan(resp(i_tr).eventtype))
            t.idx = t.presses(i_press)>=t.respwin(:,1) & t.presses(i_press)<=t.respwin(:,2);
            % not in any response window? --> FA; no reaction time
            if sum(t.idx)== 0
                resp(i_tr).button_presses_type{i_press} = 'FA';
                % check time to next event
                t.RT = t.presses(i_press) - (resp(i_tr).event_onset_times*1000);
                if any(t.RT>0) % bias to preceding events
                    resp(i_tr).button_presses_RT(i_press) = max(t.RT(t.RT>0));
                else % if no preceding event calculate negative RT
                    resp(i_tr).button_presses_RT(i_press) = max(t.RT);
                end
                resp(i_tr).button_presses_RT(i_press) = resp(i_tr).button_presses_RT(i_press);
            else
                if resp(i_tr).eventtype(t.idx)== 1
                    resp(i_tr).button_presses_type{i_press} = 'hit';
                else
                    resp(i_tr).button_presses_type{i_press} = 'FA_proper';
                end
                resp(i_tr).event_response_type{t.idx} = resp(i_tr).button_presses_type{i_press};
                % reaction time?
                resp(i_tr).button_presses_RT(i_press) = t.presses(i_press)-(resp(i_tr).event_onset_times(t.idx)*1000);
                resp(i_tr).event_response_RT(t.idx) = resp(i_tr).button_presses_RT(i_press) ;
            end
            
        else
            % no events --> all presses are false alarms; no reaction time
            resp(i_tr).button_presses_type{i_press} = 'FA';
            resp(i_tr).button_presses_RT(i_press) = nan;
        end
    end
    % check for correct responses or misses
    for i_ev = 1:resp(i_tr).eventnum
        if isempty(resp(i_tr).event_response_type)| numel(resp(i_tr).event_response_type)<i_ev
            if resp(i_tr).eventtype(i_ev)==1
                resp(i_tr).event_response_type{i_ev}='miss';
            else
                resp(i_tr).event_response_type{i_ev}='CR';
            end
            resp(i_tr).event_response_RT(i_ev) = nan;
        else
            if isempty(resp(i_tr).event_response_type{i_ev})
                if resp(i_tr).eventtype(i_ev)==1
                    resp(i_tr).event_response_type{i_ev}='miss';
                else
                    resp(i_tr).event_response_type{i_ev}='CR';
                end
                resp(i_tr).event_response_RT(i_ev) = nan;
            end
        end
    end



      

    % old wait routine
    % crttime2 = GetSecs;
    % t.timetowait = ((p.ITI(1)/1000)+RDKin.trial.duration)-(crttime2 - inittime);
    % ttt=WaitSecs(t.timetowait);
    % crttime3 = GetSecs; % for troubleshooting
    
    
end

% stop response recording
KbQueueRelease(ps.RespDev);

% send start trigger
if flag_training~=1
    PRPX_sendRecTrigger('stop')
end



end