function dispRmPosErr = remove_positioning_error(time, disp, GEOMETRIC_ERROR_MAP)
%geometricRemoveDisp = remove_positioning_error(disp, GEOMETRIC_ERROR_MAP)
% To remove the positioning error of the displacement signal


% load the geometric error fitting result
load(GEOMETRIC_ERROR_MAP,"geometric_error_pp");

% take the geometric error into account
geometricError = ppval(geometric_error_pp, disp);
dispRmPosErr = disp - geometricError;

% plot the geometric error
fig2 = figure('Name', '【IDS】位移定位误差滤除');
ax2 = axes(fig2);
yyaxis(ax2, "left");
plot(ax2, time, disp);
hold(ax2, 'on');
plot(ax2, time, dispRmPosErr);
ylabel(ax2, "Original Displacement (mm)");
y_min = min(disp);
y_max = max(disp);
if y_min > 0
    ylim([0, y_max]);
elseif y_max < 0
    ylim([y_min, 0]);
else
    ylim([y_min, y_max]);
end
yyaxis(ax2, "right");
area(ax2, time, geometricError, 0, ...
    "EdgeColor", [0.8500 0.3250 0.0980], "EdgeAlpha", 0.5, ...
    "FaceColor", [0.8500 0.3250 0.0980], "FaceAlpha", 0.1);
ylabel(ax2, "Geometric Error (mm)");
xlabel(ax2, "Time (s)");
end
