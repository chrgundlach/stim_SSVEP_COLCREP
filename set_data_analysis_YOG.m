%analyse hue angles from categ_set_YOG and plot them
%by J Martinovic (using chatgpt-6)

close all;
fclose('all');

file_path='C:\Users\jmartino\';

subjects={'3'};
categories = {'yellow';'orange';'lime';'green'};
nChromas=4; %how many chromas are tested
ntrials=6*nChromas; %how many settings per colour

% Target/Base colour palette for MAXIMUM chroma
cols={[0.98, 0.78, 0.05];[0.92, 0.40, 0.14];[0.64, 0.81, 0.22];[0.12, 0.53, 0.30]};

for ns=1:size(subjects,1)

    angles_deg=zeros(size(categories,1),ntrials);

    figure('Color', 'w');
    pax = polaraxes;
    hold on;
    
    global_max_count = 0;

    % We will store mean information inside a structured variable to plot cleanly at the end
    category_data = struct();

    for nc=1:size(categories,1)

        filename=[ subjects{ns}, '_', categories{nc}, '.csv'];
        data_table = readtable(fullfile(file_path, filename));    
        
        angles_deg(nc,:)=data_table.Hue_deg;
        angles_rad = deg2rad(angles_deg(nc,:));
        current_chromas = data_table.C;

        % Check Histogram Bin Heights for scaling
        h_temp = polarhistogram(angles_rad, 'BinWidth', deg2rad(2), 'Visible', 'off');
        if ~isempty(h_temp.Values)
            global_max_count = max(global_max_count, max(h_temp.Values));
        end
        delete(h_temp);

        % Draw a neutral underlying histogram distribution profile
        polarhistogram(angles_rad, 'BinWidth', deg2rad(2), ...
            'FaceColor', cols{nc}, 'FaceAlpha', 0.12, 'EdgeColor', 'none');

        % Get unique chroma values present in this specific file, sorted lowest to highest
        unique_C = sort(unique(current_chromas));
        min_C = min(current_chromas);
        max_C = max(current_chromas);

        % Save everything into our structure to use during the final layout sweep
        category_data(nc).angles_rad = angles_rad;
        category_data(nc).chromas = current_chromas;
        category_data(nc).unique_C = unique_C;
        category_data(nc).min_C = min_C;
        category_data(nc).max_C = max_C;
    end
    
  % --- Apply Global Axis Configurations ---
    r_max = global_max_count + 1;
    rlim(pax, [0 r_max]);
    pax.RDir = 'reverse'; 
    pax.RGrid = 'on';     
    
    % Enforce clean, whole-number counts for the circles
    pax.RTick = 0:ceil(r_max/3):r_max; 
    pax.RTickLabel = cellstr(num2str(pax.RTick(:), '%d'));
    
    % Optional: Adjust the angle where the numbers are printed so they 
    % don't clash with your data points (e.g., placing them along the 15° line)
    pax.RAxisLocation = 15; 

    % Format the Angular Grid Line Labels (Top Hemisphere Zoom)
    pax.ThetaAxis.Label.String = 'Hue Angle (Degrees)';
    thetalim(pax, [0, 180]);
    thetaticks(0:15:180);
    pax.ThetaTickLabels = cellstr(num2str(pax.ThetaTick(:), '%d°'));

    % --- Plot Data Dots and Category-Specific Means ---
    for nc=1:size(categories,1)
        angles_rad = category_data(nc).angles_rad;
        current_chromas = category_data(nc).chromas;
        unique_C = category_data(nc).unique_C;
        min_C = category_data(nc).min_C;
        max_C = category_data(nc).max_C;

        % 1. Plot the individual trial dots along the rim with dynamic pastel shifting
        for t = 1:length(angles_rad)
            if max_C > min_C
                trial_ratio = 0.15 + 0.85 * ((current_chromas(t) - min_C) / (max_C - min_C));
            else
                trial_ratio = 1.0;
            end
            trial_color = cols{nc} * trial_ratio + [1, 1, 1] * (1 - trial_ratio);
            
            polarscatter(pax, angles_rad(t), 0, 45, 'filled', ...
                'MarkerFaceColor', trial_color, 'MarkerEdgeColor', 'w', 'HandleVisibility', 'off');
        end

        % 2. Calculate and plot a separate mean line for each unique Chroma level
        num_found_chromas = length(unique_C);
        for k = 1:num_found_chromas
            this_C = unique_C(k);
            
            % Isolate trials belonging strictly to this specific chroma step
            chroma_mask = (current_chromas == this_C);
            chroma_angles_rad = angles_rad(chroma_mask);
            
            % Calculate circular mean for this chroma level
            c_mean_rad = atan2(mean(sin(chroma_angles_rad)), mean(cos(chroma_angles_rad)));
            
            % Scale line presentation dynamically:
            % Highest Chroma gets a thick solid line. Lowest Chroma gets a thin/translucent line.
            if num_found_chromas > 1
                weight_ratio = 0.25 + 0.75 * ((k - 1) / (num_found_chromas - 1));
            else
                weight_ratio = 1.0;
            end
            
            line_width = 1.0 + (3.0 * weight_ratio); % Scale thickness between 1.0 and 4.0
            line_color = cols{nc} * weight_ratio + [1, 1, 1] * (1 - weight_ratio);
            
            % Draw the split-chroma mean line from center (r_max) to outer edge (0)
            polarplot(pax, [c_mean_rad, c_mean_rad], [r_max, 0], ...
                'Color', line_color, 'LineWidth', line_width);
                
            % Place a small matching node on the outer edge to anchor the line
            polarscatter(pax, c_mean_rad, 0, 35, 'filled', ...
                'MarkerFaceColor', line_color, 'MarkerEdgeColor', 'w');
        end
        
        % 3. Finally, overlay the OVERALL global category mean line in solid black 
        global_mean_rad = atan2(mean(sin(angles_rad)), mean(cos(angles_rad)));
        polarplot(pax, [global_mean_rad, global_mean_rad], [r_max, 0], ...
            '--', 'Color', [0.2 0.2 0.2], 'LineWidth', 1.5);
    end
    
    hold off;
end