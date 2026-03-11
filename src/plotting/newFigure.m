function fig = newFigure(width, height)

    % Create figure at logical size
    fig = figure('Units','inches', ...
                 'Position',[1 1 width height], ...
                 'PaperUnits','inches', ...
                 'Renderer','painters');

    % Retina / HiDPI correction for on-screen display
    dpi = fig.ScreenPixelsPerInch;   % e.g., 110, 120, 144 depending on scaling
    scale = dpi / 72;                % MATLAB assumes 72 DPI
    fig.Position(3:4) = [width height] * scale;

end