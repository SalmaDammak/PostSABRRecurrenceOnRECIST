function hROC = PlotROCWithErrorBounds(m2dXAndError, m2dYAndError, dOptimalThresholdPointIndex, vdColour)

hROC = figure();
hold('on');
axis('square');

%vdFigDims_cm = [17/2 17/2];
vdFigDims_cm = [17 17];
hROC.Units = 'centimeters';

vdPos = hROC.Position;
vdPos(3:4) = vdFigDims_cm;
hROC.Position = vdPos;

plot(m2dXAndError(:,1), m2dYAndError(:,1), '-', 'Color', vdColour, 'LineWidth', 1.5);

hPatch = patch('XData', [m2dXAndError(:,2); flipud(m2dXAndError(:,3))], 'YData', [m2dYAndError(:,3); flipud(m2dYAndError(:,2))]);
hPatch.FaceColor = vdColour;
hPatch.LineStyle = 'none';
hPatch.FaceAlpha = 0.25;

hold on

%operating point
plot(m2dXAndError(dOptimalThresholdPointIndex,1), m2dYAndError(dOptimalThresholdPointIndex,1), 'Marker', '+', 'MarkerSize', 8, 'Color', [0 0 0], 'LineWidth', 1.5);

hold on

plot([0 1], [0, 1], '--k', 'LineWidth', 1.5);

ylim([0, 1]);
xlim([0, 1]);

xticks(0:0.1:1);
yticks(0:0.1:1);

grid('on');

ylabel('True Positive Rate');
xlabel('False Positive Rate');

fontsize(18,'points')
fontname('calibri')
end