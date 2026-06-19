function Pr_dBm = calcolaFriis(d, f_Hz, Pt_dBm, Gt_dBi, Gr_dBi)

c = 3e8; % Velocità della luce (m/s)
lambda = c / f_Hz; % Lunghezza d'onda

% Calcolo dell'attenuazione di spazio libero (Free Space Path Loss) in dB
% Formula: PL(dB) = 20*log10(4*pi*d / lambda)
PL_dB = 20 * log10((4 * pi * d) / lambda);

% La potenza ricevuta è la potenza trasmessa + guadagni - attenuazione
Pr_dBm = Pt_dBm + Gt_dBi + Gr_dBi - PL_dB;
end