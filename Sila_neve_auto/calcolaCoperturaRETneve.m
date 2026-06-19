function potenza_min = calcolaCoperturaRETneve(drone_X, drone_Y, drone_Z, ...
                                        socc_X, socc_Y, socc_Z, F_dem, frequenza, Pt_drone, Gt, Gr, ...
                                        veg_X_min, veg_X_max, veg_Y_min, veg_Y_max, veg_altezza, ...
                                        alfa_RET, beta_RET, W_RET, sigma_tau_RET, ...
                                        tasso_nevicata_Rs, coeff_neve_a, coeff_neve_b)
    
    nPuntiRaggio = 50; 
    numSoccorritori = length(socc_X);
    potenze_ricevute = zeros(1, numSoccorritori);
    
    t = linspace(0, 1, nPuntiRaggio);
    
    for i = 1:numSoccorritori
        sX = socc_X(i); sY = socc_Y(i); sZ = socc_Z(i);
        distanza_3D = sqrt((sX - drone_X)^2 + (sY - drone_Y)^2 + (sZ - drone_Z)^2);
        
        raggio_X = drone_X + t * (sX - drone_X);
        raggio_Y = drone_Y + t * (sY - drone_Y);
        raggio_Z = drone_Z + t * (sZ - drone_Z);
        
        z_terreno_raggio = F_dem(raggio_X, raggio_Y);
        clearance = raggio_Z - z_terreno_raggio;
        
        % 1. Calcolo Spazio Libero (Friis)
        PotenzaRx = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
        
        % 2. Ostruzione Morfologica (Knife-Edge)
        if any(clearance < 0)
            [min_clearance, idx_ost] = min(clearance);
            h_ostacolo = abs(min_clearance);
            d1 = t(idx_ost) * distanza_3D;
            d2 = distanza_3D - d1;
            PotenzaRx = PotenzaRx + calcolaKnifeEdge(h_ostacolo, d1, d2, frequenza);
        end
        
        % 3. Attenuazione Ambientale (Modello RET)
        punti_in_veg = (raggio_X >= veg_X_min & raggio_X <= veg_X_max) & ...
                       (raggio_Y >= veg_Y_min & raggio_Y <= veg_Y_max) & ...
                       (raggio_Z >= z_terreno_raggio & raggio_Z <= (z_terreno_raggio + veg_altezza));
        step_raggio = distanza_3D / (nPuntiRaggio - 1);
        d_veg = sum(punti_in_veg) * step_raggio;
        if d_veg > 0
            PotenzaRx = PotenzaRx - calcolaRET(d_veg, alfa_RET, beta_RET, W_RET, sigma_tau_RET);
        end
        
        % 4. Attenuazione Neve in caduta
        PotenzaRx = PotenzaRx - calcolaNeve(distanza_3D, tasso_nevicata_Rs, coeff_neve_a, coeff_neve_b);
        
        potenze_ricevute(i) = PotenzaRx;
    end
    
    potenza_min = min(potenze_ricevute);
end