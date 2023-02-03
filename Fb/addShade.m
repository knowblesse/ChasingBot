function addShade(x, m, s, c)
% Draw Result
curve1 = m + s;
curve2 = m - s;
fill([x,fliplr(x)]',[curve1;flipud(curve2)], c, 'FaceAlpha', 0.3, 'LineStyle', 'none');

