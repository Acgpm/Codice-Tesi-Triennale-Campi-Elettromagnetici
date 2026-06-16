function [X_metri, Y_metri, Z_metri] = importaMappaSAR(nomeFileMappa)

% readgeoraster e una funzione che legge i file geospaziali restituendo Z
% (matrice con altezze di ogni punto) ed R (contiene le informazioni di
% riferimento geografico, come i confini della mappa)
    [Z, R] = readgeoraster(nomeFileMappa);
    Z = double(Z);

% size conta quante righe e colonne di dati ci sono nella mappa
% (risoluzione in pixel), mentre meshgrid crea le matrici che contengono le
% coordinate dei pixel di tutta la griglia
    [numRighe, numColonne] = size(Z);
    [X_pixel, Y_pixel] = meshgrid(1:numColonne, 1:numRighe);

% Conversione delle informazioni in coordinate reali terrestri
    [Lat, Lon] = intrinsicToGeographic(R, X_pixel, Y_pixel);

% Calcolo del centro geografico della mappa. Viene calcolato anche il
% minimo valore di altitudine
    lat_centro = mean(Lat(:));
    lon_centro = mean(Lon(:));
    alt_centro = min(Z(:));

% wgs84Ellipsoid serve per definire il modello matematico standard della
% forma della terra. geodetic2ned è una funzione che prende latitudine, 
% longitudine e altitudine in gradi e le proietta nel sistema metrico
% piatto Nord est sud orientato rispetto al centro della mappa calcolato in
% precedenza, ottenendo una mappa espressa in metri. 
    sferoide = wgs84Ellipsoid;
    [X_metri, Y_metri, Z_metri] = geodetic2ned(Lat, Lon, Z, lat_centro, lon_centro, alt_centro, sferoide);

% Visualizzazione 3D della morfologia del terreno
    figure('Name', 'Morfologia del Terreno Extra-Urbano (SAR)', 'Color', 'w', 'Position', [100, 100, 1000, 700]);
    surf(X_metri, Y_metri, Z_metri, 'EdgeColor', 'none');

% Creazione di una palette cromatica di colori per un paesaggio montano
    sfumaturaRealistica = [
        0.1, 0.4, 0.1;
        0.2, 0.6, 0.2;
        0.4, 0.5, 0.3;
        0.5, 0.4, 0.3;
        0.7, 0.6, 0.5;
    ];
    colormap(interp1(linspace(0,1,size(sfumaturaRealistica,1)), sfumaturaRealistica, linspace(0,1,256)));
    
% Applicazione cromatica per la personalizzazione del testo
    coloreTesto = [0.1, 0.1, 0.1];
    title('Analisi Morfologica del Terreno - Scenario Missione SAR', 'Color', coloreTesto, 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Distanza Est / Asse X (metri)', 'Color', coloreTesto, 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Distanza Nord / Asse Y (metri)', 'Color', coloreTesto, 'FontSize', 12, 'FontWeight', 'bold');
    zlabel('Altezza Relativa / Asse Z (metri)', 'Color', coloreTesto, 'FontSize', 12, 'FontWeight', 'bold');
    
% Questa sezione serve per stringere i margini del grafico per eliminare
% gli spazi vuoti che delle volte MATLAB crea
    ax = gca;
    grid on; view(3); axis tight;
    
% personalizzazione cromatica degli assi
    ax.XColor = coloreTesto; ax.YColor = coloreTesto; ax.ZColor = coloreTesto;
    ax.FontSize = 10; ax.LineWidth = 1.2;
    ax.GridColor = [0, 0, 0]; ax.GridAlpha = 0.4;

% leggenda dei colori per altitudine
    c = colorbar;
    c.Label.String = 'Elevazione Terreno (metri)';
    c.Label.Color = coloreTesto; c.Label.FontSize = 11; c.Color = coloreTesto;

% Illuminazione del modello 3D con tutte le proprietà fisiche di 
% ombreggiatura e riflessione del terreno
    camlight('headlight');
    light('Position', [1000, 1000, 2000], 'Style', 'local');
    lighting gouraud;
    material([0.4 0.4 0.1]);
end