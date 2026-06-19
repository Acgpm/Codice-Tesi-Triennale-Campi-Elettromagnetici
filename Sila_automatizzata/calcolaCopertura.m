function potMinima = calcolaCopertura (drone_X, drone_Y, drone_Z, socc_X, socc_Y, socc_Z, F_dem, frequenza, Pt_drone, Gt, Gr)

% creiamo un vettore di dimensione numero soccorritori per le potenze,
% parametriziamo la linea tratteggiata in 100 punti, e successivamente
% facciamo il solito calcolo della clearance per capire che modello di
% propagazione utilizzare
    numSoccorritori = length(socc_X);
    potenze_Rx = zeros(1, numSoccorritori); 
    t = linspace(0, 1, 100);

    for i=1:numSoccorritori
        sX = socc_X(i); sY = socc_Y(i); sZ = socc_Z(i);
        distanza_3D = sqrt((sX - drone_X)^2 + (sY - drone_Y)^2 + (sZ - drone_Z)^2);

        raggio_X = drone_X + t * (sX - drone_X);
        raggio_Y = drone_Y + t * (sY - drone_Y);
        raggio_Z = drone_Z + t * (sZ - drone_Z);

        z_terreno_raggio = F_dem(raggio_X, raggio_Y);
        clearance = raggio_Z - z_terreno_raggio;

        if all(clearance >= 0)
            potenze_Rx(i) = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
        else
            [min_clearance, indice_ostacolo] = min(clearance);
            h_ostacolo = abs(min_clearance);
            d1 = t(indice_ostacolo) * distanza_3D;
            d2 = distanza_3D - d1;

            PerditaDiffrazione = calcolaKnifeEdge(h_ostacolo, d1, d2, frequenza);
            PotenzaBase = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
            potenze_Rx(i) = PotenzaBase + PerditaDiffrazione;
        end
    end
    potMinima = min(potenze_Rx);
end