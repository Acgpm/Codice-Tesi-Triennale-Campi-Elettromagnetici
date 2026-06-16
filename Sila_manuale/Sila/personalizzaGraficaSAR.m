function personalizzaGraficaSAR(ax, lgd)
% personalizzaGraficaSAR Applica un contrasto scuro e uniforme a testi, assi e legenda

ColoreScuro = [0.1, 0.1, 0.1]; % Tonalità quasi nera nitida

% Applicazione agli assi e ai numeri delle coordinate
ax.XColor = ColoreScuro;
ax.YColor = ColoreScuro;
ax.ZColor = ColoreScuro;

% Applicazione alle etichette di testo e al titolo
ax.Title.Color  = ColoreScuro;
ax.XLabel.Color = ColoreScuro;
ax.YLabel.Color = ColoreScuro;
ax.ZLabel.Color = ColoreScuro;

% Applicazione al testo della legenda
lgd.TextColor = ColoreScuro;
end