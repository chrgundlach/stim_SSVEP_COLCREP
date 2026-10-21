%% Navigate standard and Propixx LCh color spaces

try
    listbox.options = {'Standard Monitor','ProPixx'};
    listbox.choiceIndex = listdlg('ListString', listbox.options, ...
        'PromptString','Display type?','ListSize',[300,100],'SelectionMode','single');
    switch listbox.options{listbox.choiceIndex}
        case 'Standard Monitor'
            gamutField = 'stdInGamut';
            colorField = 'stdRGB';
        case 'ProPixx'
            gamutField = 'ppInGamut';
            colorField = 'ppRGB';
    end

    %% Create Color spaces: LCh
    numSteps = 301;
    [aVals, bVals, LVals] = meshgrid(linspace(-150,150,numSteps),linspace(-150,150,numSteps),linspace(-10,110,121));
    abTable = table((1:numel(aVals))',[LVals(:),aVals(:),bVals(:)],'VariableNames',{'index', 'Lab'});
    abTable.XYZ = lab2xyz(abTable.Lab);
    abTable.xyY = XYZToxyY(abTable.XYZ')';
    abTable.LCh = [abTable.Lab(:,1),...
        hypot(abTable.Lab(:,2),abTable.Lab(:,3)),...
        mod(atan2d(abTable.Lab(:,3),abTable.Lab(:,2)) + 360, 360)];
    % transform XYZ colors to RGB space using Propixx profile
    abTable.ppRGB = xyz2rgb_custom(abTable.XYZ,[0.665 0.321], [0.172 0.726], [0.163 0.039], [0.3127 0.3290]);
    abTable.ppInGamut = (abTable.ppRGB(:,:)<=1 & abTable.ppRGB(:,:)>=0);
    abTable.stdRGB = xyz2rgb(abTable.XYZ);
    abTable.stdInGamut = (abTable.stdRGB(:,:)<=1 & abTable.stdRGB(:,:)>=0);

    [~,uniqueRows] = unique(round(abTable.stdRGB*255),'rows','stable');
    abTable = abTable(uniqueRows,:);

    currentLightness = 63;
    currentChroma = 60;
    selectionHues = [101, 71, 131, 170, 301]'; % with high chroma=72, lightness=68 (0.38 grey): : orange, yellow, green, blue

    %     selectionHues = [148 82 336 41]'; % with chroma=86, lightness=68 (0.38 grey): green, brownish, pink, reddish
    % selectionHues = [126 84 352 42 176]'; %  with chroma=72, lightness=68 (0.38 grey): green, brownish, pink, reddish, bluish
    %     selectionHues = [148 58 328 238]'; % color order upper left - upper
    %     right - lower right - lower left
    %     selectionHues = [148 68 336 204]'; % 4th turquoise, higher luminance possible (0.5 grey == lightness of ~76)
    %     selectionHues = [148 58 328 360]'; % 4th magenta, higher chroma possible, same luminance (0.38 grey == lightness of 68)

    %% Initialize & open window
    ListenChar(2);
    KbName('UnifyKeyNames'); % buggy (scope issue?)
    RestrictKeysForKbCheck([]);
    PsychImaging('PrepareConfiguration');
    Screen('Preference', 'SkipSyncTests', 2);
    [window,screenRect] = PsychImaging('OpenWindow', 1, [0 0 0]);
    Screen('ColorRange', window,1,[],1); % clamping color range to 1 also has good effects on graphic card communication...sometimes
    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    Screen('TextSize', window, 24); % font size in pixels
    try
        Datapixx('Open');
        Datapixx('SetPropixxDlpSequenceProgram', 0);
        Datapixx('RegWrRd');
    end

    %% Drawing parameters
    eccScalar = 5;
    dotSize = 3;
    selectionRect = AlignRect([0 0 400 400],screenRect,'center','right');

    %% Vector of Cannon-scaling
    switch listbox.options{listbox.choiceIndex}
        case 'Standard Monitor'
            startStdRGB = [.0611 .527 .666]; % standard blue
            cannonSweep = table;
            cannonSweep.lumScalar = (.2:.001:2)';
            cannonSweep.scaledRGB = startStdRGB.*cannonSweep.lumScalar;
            cannonSweep.scaledLabCh = rgb2lab(cannonSweep.scaledRGB);
            cannonSweep.scaledLabCh(:,[4,5]) = [hypot(cannonSweep.scaledLabCh(:,2),cannonSweep.scaledLabCh(:,3)), wrapTo360(atan2d(cannonSweep.scaledLabCh(:,3),cannonSweep.scaledLabCh(:,2)))];
        case 'ProPixx'
            startPpRGB = [.00867 .262 .503];
            cannonSweep = table;
            cannonSweep.lumScalar = (.2:.001:2)';
            cannonSweep.scaledRGB = startPpRGB.*cannonSweep.lumScalar;
            cannonSweep.scaledLabCh = xyz2lab(rgb2xyz_custom(cannonSweep.scaledRGB,[0.665 0.321], [0.172 0.726], [0.163 0.039], [0.3127 0.3290] ));
            cannonSweep.scaledLabCh(:,[4,5]) = [hypot(cannonSweep.scaledLabCh(:,2),cannonSweep.scaledLabCh(:,3)), wrapTo360(atan2d(cannonSweep.scaledLabCh(:,3),cannonSweep.scaledLabCh(:,2)))];
    end

    while 1
        %% ---------------------
        planeTable = abTable(abTable.Lab(:,1)==currentLightness,:);
        [~,cannonIndex] = min(abs(cannonSweep.scaledLabCh(:,1)-currentLightness));
        cannonSingle = cannonSweep(cannonIndex,:);

        %% Lab Space Plot
        Screen('DrawDots',window,...
            transpose([1,-1].*eccScalar.*planeTable.Lab(:,[2,3])),...
            dotSize.*all(planeTable.(gamutField),2) + 1,...
            transpose(planeTable.(colorField)(:,:)),...
            screenRect([3 4])./2,0);

        %% Cannon Vector plot
        Screen('FrameRect',window,[1 1 1],...
            screenRect([3 4 3 4])./2 + [1,-1,1,-1].*eccScalar.*cannonSingle.scaledLabCh(:,[2,3,2,3]) + [-2 -2 2 2],1);

        %% Draw Gray
        grayColor = planeTable.(colorField)(planeTable.Lab(:,2)==0 & planeTable.Lab(:,3)==0,:);
        DrawFormattedText(window,[...
            'L* = ' num2str(currentLightness) newline,...
            'Gray = ' mat2str(grayColor,3) newline,...
            ],20,20,[1,1,1]);
        Screen('FillArc',window,grayColor,selectionRect,0,360);
        Screen('DrawDots',window,...
            [0;0],...
            dotSize.*8,...
            transpose(grayColor),...
            screenRect([3 4])./2,1);

        %% Draw Chosen Colors
        abTableSelecCol = table((1:numel(selectionHues))',zeros(numel(selectionHues),1),zeros(numel(selectionHues),3),zeros(numel(selectionHues),3),'VariableNames',{'index', 'hueAngle','goalLCh','goalLab'});
        for iS = 1:length(selectionHues)
            if iS==0
                aSelectedColor.LabCh = [currentLightness, ...
                    2*currentChroma.*cosd(selectionHues(iS)),...
                    2*currentChroma.*sind(selectionHues(iS)),...
                    2*currentChroma, selectionHues(iS)];
            else
                aSelectedColor.LabCh = [currentLightness, ...
                    currentChroma.*cosd(selectionHues(iS)),...
                    currentChroma.*sind(selectionHues(iS)),...
                    currentChroma, selectionHues(iS)];
            end
            aSelectedColor.ppRGB = xyz2rgb_custom(lab2xyz(aSelectedColor.LabCh(1:3)),[0.665 0.321], [0.172 0.726], [0.163 0.039], [0.3127 0.3290]);
            aSelectedColor.stdRGB = xyz2rgb(lab2xyz(aSelectedColor.LabCh(1:3)));
            aSelectedColor.ppInGamut = (aSelectedColor.ppRGB(:,:)<=1 & aSelectedColor.ppRGB(:,:)>=0);
            aSelectedColor.stdInGamut = (aSelectedColor.stdRGB(:,:)<=1 & aSelectedColor.stdRGB(:,:)>=0);

            % store selected colors
            abTableSelecCol.hueAngle(iS) = selectionHues(iS);
            abTableSelecCol.goalLab(iS,:) = aSelectedColor.LabCh(1:3);
            abTableSelecCol.goalLCh(iS,:) = [abTableSelecCol.goalLab(iS,1),...
                hypot(abTableSelecCol.goalLab(iS,2),abTableSelecCol.goalLab(iS,3)),...
                mod(atan2d(abTableSelecCol.goalLab(iS,3),abTableSelecCol.goalLab(iS,2)) + 360, 360)];
            abTableSelecCol.goalPpRGB(iS,:) = aSelectedColor.ppRGB;
            abTableSelecCol.goalStdRGB(iS,:) = aSelectedColor.stdRGB;
            abTableSelecCol.ppInGamut(iS,:) = aSelectedColor.ppInGamut;
            abTableSelecCol.stdInGamut(iS,:) = aSelectedColor.stdInGamut;


            Screen('DrawDots',window,...
                transpose([1,-1].*eccScalar.*aSelectedColor.LabCh([2,3])),...
                dotSize.*8,...
                transpose(aSelectedColor.(colorField)),...
                screenRect([3 4])./2,1);

            Screen('FillArc',window,aSelectedColor.(colorField),GrowRect(selectionRect,-50,-50),(360/length(selectionHues))*iS,360/length(selectionHues));

            if ~all(aSelectedColor.(gamutField))
                textColor = [1 0 0];
                extraMsg = '(Out of gamut!)';
                Screen('FrameArc',window,textColor,GrowRect(selectionRect,-50,-50),(360/length(selectionHues))*iS,360/length(selectionHues),3,3);
            else
                textColor = [1 1 1];
                extraMsg = '';
            end

            DrawFormattedText(window,[...
                'Color ' num2str(iS) ' ' extraMsg newline,...
                '---------------------' newline,...
                'Lab = ' mat2str(aSelectedColor.LabCh(1:3),3) newline,...
                'Chroma = ' num2str(aSelectedColor.LabCh(4),'%2.1f') newline,...
                'Hue = ' num2str(aSelectedColor.LabCh(5),'%3.1f') 'º' newline,...
                'Std RGB = ' mat2str(aSelectedColor.stdRGB,3) newline,...
                'ProPixx RGB = ' mat2str(aSelectedColor.ppRGB,3) newline,...
                ],20,220*iS - 100,textColor);

        end

        DrawFormattedText(window,[...
            'Up/Down: Adjust Lightness Plane' newline,...
            'Left/Right: Adjust Chroma Radius' newline,...
            'Escape: Exit' newline,...
            ],screenRect(1)+10,screenRect(4)-80,[1,1,1]);
        DrawFormattedText(window,['Display Type: ' ...
            listbox.options{listbox.choiceIndex}],...
            'center',20,[1,1,1]);

        %% Update
        Screen('Flip',window);

        %% Keyboard controls
        [~,keyCode] = KbWait([],0);
        switch KbName(find(keyCode,1,'first'))
            case '1!'
                currentLightness = 43; currentChroma = 28;
            case '2@'
                currentLightness = 52; currentChroma = 32;
            case '3#'
                currentLightness = 64; currentChroma = 38;
            case '4$'
                currentLightness = 53; currentChroma = 24;
            case 'UpArrow'
                currentLightness = min(currentLightness+1,110);
            case 'DownArrow'
                currentLightness = max(currentLightness-1,-10);
            case 'LeftArrow'
                currentChroma = max(currentChroma-2, 0);
            case 'RightArrow'
                currentChroma = currentChroma+2;
            case 'ESCAPE'
                break;
            otherwise
                disp(KbName(keyCode));
        end

    end

catch theError
end

ListenChar(0);
sca;
try
    Datapixx('SetPropixxDlpSequenceProgram', 0);
    Datapixx('RegWrRd');
    Datapixx('close');
end