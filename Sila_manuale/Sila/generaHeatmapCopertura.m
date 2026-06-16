function [Heatmap_Power, fig_heatmap] = generaHeatmapCopertura(X_metri, Y_metri, F_dem, ...
    drone_X, drone_Y, drone_Z, socc_X, socc_Y, socc_altezzaPersona, ...
    Pt_drone, Gt, Gr, frequenza, passo_griglia)
% GENERAHEATMAPCOPERTURA Calcola e visualizza la heatmap 2D (contour) della potenza
    
% Questo controllo serve per capire se sono stati passati tutti i
% parametri, in particolare a settare una risoluzione di default nel caso
% in cui non sia stata specificata
    if nargin < 14
        passo_griglia = 20; 
    end

    disp('Generazione Heatmap');

    % Qui viene definita la griglia 2D, utilizzando sempre la funzione
    % interpolante per trovare la Z ad ogni punto di essa.
    x_min = min(X_metri(:)); x_max = max(X_metri(:));
    y_min = min(Y_metri(:)); y_max = max(Y_metri(:));
    
    [X_grid, Y_grid] = meshgrid(x_min:passo_griglia:x_max, y_min:passo_griglia:y_max);
    Z_grid = F_dem(X_grid, Y_grid); 
    
    %Qui viene allocata in memoria la matrice di dimensione pari al numero
    %di righe e colonne che ci serve
    [numRighe, numColonne] = size(X_grid);
    Heatmap_Power = zeros(numRighe, numColonne);
    
    % Qui viene creato un vettore di 30 punti discreti tra 0 e 1 per
    % parametrizzare la retta che unisce drone e ricevitore per la verifica
    % dell'ostruzione visiva
    nPuntiRaggio_HM = 30; 
    t_h = linspace(0, 1, nPuntiRaggio_HM);
    
    % 2. Calcolo della potenza su tutta la mappa
    for r = 1:numRighe
        for c = 1:numColonne
            pX = X_grid(r, c);
            pY = Y_grid(r, c);
            pZ = Z_grid(r, c) + socc_altezzaPersona;
            
            dist_3D = sqrt((pX - drone_X)^2 + (pY - drone_Y)^2 + (pZ - drone_Z)^2);
            
            % Per una distanza così breve la potenza ricevuta è pari a quella trasmessa
            if dist_3D < 1 
                Heatmap_Power(r,c) = Pt_drone;
                continue;
            end
            
            % Anche qui parametrizziamo il segmento per poter trattare con
            % dei punti lungo la linea visiva, applicando la formula
            % matematica P(t) = P_drone + t*(P_ricevitore-P_drone) con t
            % appartenente all'intervallo [0,1]
            rag_X = drone_X + t_h * (pX - drone_X);
            rag_Y = drone_Y + t_h * (pY - drone_Y);
            rag_Z = drone_Z + t_h * (pZ - drone_Z);
            
            %Qui viene calcolata l'altezza del terreno sotto i vari punti
            %del raggio, in modo da calcolare la clearance
            z_terr_rag = F_dem(rag_X, rag_Y);
            clearance_h = rag_Z - z_terr_rag;
            
            % Qui semplicemente si applicano i modelli di propagazione
            % visti anche nel main
            if all(clearance_h >= 0) 
                Heatmap_Power(r, c) = calcolaFriis(dist_3D, frequenza, Pt_drone, Gt, Gr);
            else 
                [min_cl, ind_ost] = min(clearance_h);
                h_ost = abs(min_cl);
                d1_h = t_h(ind_ost) * dist_3D;
                d2_h = dist_3D - d1_h;
                
                P_base = calcolaFriis(dist_3D, frequenza, Pt_drone, Gt, Gr);
                P_diff = calcolaKnifeEdge(h_ost, d1_h, d2_h, frequenza);
                Heatmap_Power(r, c) = P_base + P_diff;
            end
        end
    end
    
%% Qui effettuiamo la personalizzazione cromatica della mappa
    fig_heatmap = figure('Name', 'Mappa di Copertura 2D (Heatmap)', 'Color', 'w', 'Position', [150, 150, 800, 650]);
    
    % Creazione del grafico a curve di livello riempite (Contour)
    contourf(X_grid, Y_grid, Heatmap_Power, 20, 'LineStyle', 'none');
    colormap turbo; % Colormap ad alto contrasto, ottima per i segnali RF
    
    % Questa funzione forza la scala dei colori a restare in un range di
    % DBm realistico, tra i -120 definiti come zona morta, ed i -50
    % definiti come segnale eccellente
    caxis([-120, -50]); 
    
    c = colorbar;
    c.Label.String = 'Potenza Ricevuta [dBm]';
    c.Label.FontWeight = 'bold';
    hold on; grid on;
    
    % Plotta la posizione dei soccorritori sulla mappa 2D
    plot(socc_X, socc_Y, 'w^', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'Soccorritori');
    for i = 1:length(socc_X)
        % Testo bianco per contrastare meglio sui colori di sfondo della heatmap
        text(socc_X(i) + 15, socc_Y(i) + 15, ['S', num2str(i)], 'Color', 'w', 'FontWeight', 'bold');
    end
    
    % Plotta la posizione del Drone
    plot(drone_X, drone_Y, 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'LineWidth', 2, 'DisplayName', 'Drone');
    text(drone_X + 20, drone_Y + 20, 'DRONE', 'Color', 'k', 'FontWeight', 'bold');
    
    title('Heatmap della Potenza Ricevuta (Contour)');
    xlabel('Distanza Est (X) [m]');
    ylabel('Distanza Nord (Y) [m]');
    legend('Location', 'northeast');
    
    % Uniformiamo lo stile estetico scuro come per il grafico 3D
    ax2 = gca;
    ColoreScuro = [0.1 0.1 0.1];
    ax2.XColor = ColoreScuro; ax2.YColor = ColoreScuro;
    ax2.Title.Color = ColoreScuro; ax2.XLabel.Color = ColoreScuro; ax2.YLabel.Color = ColoreScuro;
    
    disp('Heatmap completata.');
end