function [Matrice_Potenza_HM, figura_HM] = generaHeatmapCopertura(X_metri, Y_metri, F_dem, ...
    drone_X, drone_Y, drone_Z, socc_X, socc_Y, socc_altezzaPersona, ...
    Pt_drone, Gt, Gr, frequenza, risoluzione_griglia, ...
    veg_X_min, veg_X_max, veg_Y_min, veg_Y_max, veg_altezza, ...
    alfa_RET, beta_RET, W_RET, sigma_tau_RET, ...
    tasso_nevicata_Rs, coeff_neve_a, coeff_neve_b) % <--- Parametri neve aggiunti qui

    % 1. Creazione dei vettori della griglia spaziale
    x_min = min(X_metri(:)); x_max = max(X_metri(:));
    y_min = min(Y_metri(:)); y_max = max(Y_metri(:));
    
    x_grid = x_min:risoluzione_griglia:x_max;
    y_grid = y_min:risoluzione_griglia:y_max;
    
    Matrice_Potenza_HM = zeros(length(y_grid), length(x_grid));
    
    nPuntiRaggio = 30; 
    
    h_wait = waitbar(0, 'Generazione Heatmap 2D con attenuazione vegetazione e neve...');
    
    % 2. Calcolo della potenza per ogni pixel della griglia
    for i = 1:length(x_grid)
        for j = 1:length(y_grid)
            rx_X = x_grid(i);
            rx_Y = y_grid(j);
            
            rx_Z = F_dem(rx_X, rx_Y) + socc_altezzaPersona;
            
            distanza_3D = sqrt((rx_X - drone_X)^2 + (rx_Y - drone_Y)^2 + (rx_Z - drone_Z)^2);
            
            t = linspace(0, 1, nPuntiRaggio);
            raggio_X = drone_X + t * (rx_X - drone_X);
            raggio_Y = drone_Y + t * (rx_Y - drone_Y);
            raggio_Z = drone_Z + t * (rx_Z - drone_Z);
            
            z_terreno_raggio = F_dem(raggio_X, raggio_Y);
            clearance = raggio_Z - z_terreno_raggio;
            
            PotenzaBase = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
            Potenza_Pixel = PotenzaBase;
            
            if any(clearance < 0)
                [min_clearance, idx_ost] = min(clearance);
                h_ost = abs(min_clearance);
                d1 = t(idx_ost) * distanza_3D;
                d2 = distanza_3D - d1;
                Potenza_Pixel = PotenzaBase + calcolaKnifeEdge(h_ost, d1, d2, frequenza);
            end
            
            punti_in_veg = (raggio_X >= veg_X_min & raggio_X <= veg_X_max) & ...
                           (raggio_Y >= veg_Y_min & raggio_Y <= veg_Y_max) & ...
                           (raggio_Z >= z_terreno_raggio & raggio_Z <= (z_terreno_raggio + veg_altezza));
            
            step_raggio = distanza_3D / (nPuntiRaggio - 1);
            d_veg = sum(punti_in_veg) * step_raggio;
            
            if d_veg > 0
                Potenza_Pixel = Potenza_Pixel - calcolaRET(d_veg, alfa_RET, beta_RET, W_RET, sigma_tau_RET);
            end
            
            % Applicazione modello Neve
            Potenza_Pixel = Potenza_Pixel - calcolaNeve(distanza_3D, tasso_nevicata_Rs, coeff_neve_a, coeff_neve_b);
            
            Matrice_Potenza_HM(j, i) = Potenza_Pixel;
        end
        waitbar(i/length(x_grid), h_wait);
    end
    close(h_wait);
    
    % 3. Render Grafico della Heatmap
    figura_HM = figure('Name', 'Heatmap della Potenza Ricevuta (con RET e Neve)', 'Color', 'w', 'Position', [150, 150, 800, 600]);
    
    contourf(x_grid, y_grid, Matrice_Potenza_HM, 40, 'LineStyle', 'none'); 
    
    colormap(jet); 
    
    c = colorbar;
    c.Label.String = 'Potenza Ricevuta [dBm]';
    c.Label.FontWeight = 'bold';
    hold on;
    
    pos_veg = [veg_X_min, veg_Y_min, veg_X_max - veg_X_min, veg_Y_max - veg_Y_min];
    rectangle('Position', pos_veg, 'EdgeColor', 'g', 'LineWidth', 2.5, 'LineStyle', '--');
    text(veg_X_min + 10, veg_Y_max - 20, 'Area Boschiva (RET)', 'Color', 'g', 'FontWeight', 'bold', 'BackgroundColor', 'k', 'Margin', 1);
    
    plot(drone_X, drone_Y, 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    text(drone_X + 25, drone_Y, 'DRONE', 'FontWeight', 'bold', 'Color', 'k');
    
    for k = 1:length(socc_X)
        plot(socc_X(k), socc_Y(k), '^', 'MarkerSize', 9, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
        text(socc_X(k) + 20, socc_Y(k), sprintf('S%d', k), 'FontWeight', 'bold', 'Color', 'w', 'BackgroundColor', 'k', 'Margin', 1);
    end
    
    title('Heatmap della Potenza Ricevuta (Grid Search con RET e Neve)', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Distanza Est (X) [m]', 'FontWeight', 'bold');
    ylabel('Distanza Nord (Y) [m]', 'FontWeight', 'bold');
    grid on;
end