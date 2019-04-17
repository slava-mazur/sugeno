library(plotly)
library(dplyr)
library(lubridate)
library(xts)
library(ggplot2)
library(PerformanceAnalytics)
library(KernSmooth)
library(car)

scatter_plotly = function(X, idx = 1:3, Class = NULL, show_text = FALSE, text = NULL, colors = NULL, marker_size = 2) {
    cnames = colnames(X);
    X = as.data.frame(X[, c(idx, Class)]);
    if (is.null(cnames)) {
        colnames(X)[1:length(idx)] = cnames= paste0('x', 1:length(idx));
        if (!is.null(Class) && is.character(Class)) colnames(X)[ncol(X)] = Class;
    }
    if (is.null(rownames(X))) {
        rownames(X) = as.character(1:nrow(X));
    }
    if (!is.null(Class)) X[, ncol(X)] = as.factor(X[, ncol(X)]) else X = cbind(X, data.frame(Class = as.factor(rep(0, nrow(X)))));
    if (is.null(colors)) colors = c('#0C4B8E', '#BF382A');
    font = list(
        family = "sans serif",
        size = 10,
        color = toRGB("grey50"));
    if (length(idx) > 2) {
        res = plot_ly(X, x = X[,1], y = X[,2], z = X[,3], color = X[,4], colors = colors, mode = "markers", marker = list(size=marker_size)) %>%
            add_markers(text = text) %>%
            layout(scene = list(xaxis = list(title = cnames[1]),
                                yaxis = list(title = cnames[2]),
                                zaxis = list(title = cnames[3])));
        if (show_text)
            res = add_text(res, x = X[,1], y = X[,2], z = X[,3], text = if(is.null(text)) rownames(X) else text, textfont = font, textposition = "top")
    } else {
        res = plot_ly(X, x = X[,1], y = X[,2], color = X[,3], colors = colors, mode = "markers", marker = list(size=marker_size)) %>%
            add_markers(text = text) %>%
            layout(scene = list(xaxis = list(title = cnames[1]),
                                yaxis = list(title = cnames[2])));
        if (show_text)
            res = add_text(res, x = X[,1], y = X[,2], text = if(is.null(text)) rownames(X) else text, textfont = font, textposition = "top")
    }
    res
}

ts_plotly = function(z, colors = c('#000000', '#0000FF', '#BF382A', '#0C4B8E'), line_width = 1, marker_size = 0, dtick = 'M12', 
                     date_fmt = '%Y-%m-%d', value_fmt = NULL, ...) {
    if (is.null(colnames(z))) colnames(z) = paste0('x', 1:ncol(z));
    z = data.frame(date=time(z), as.data.frame(z)) %>% filter(!is.na(date));
    if (line_width[1] > 0) mode = 'lines';
    if (marker_size[1] > 0) if (line_width[1] > 0) mode = 'lines+markers' else mode= 'markers';
    res = plot_ly(data = z, x = z[,1], y = z[,2], type='scatter', mode=mode, color = I(colors[1]), 
                  line= if (line_width[1] > 0) list(width = line_width[1]) else NULL, 
                  marker = if (marker_size[1] > 0) list(size=marker_size[1]) else NULL, 
                  name = colnames(z)[2], 
                  text = if (is.null(value_fmt)) NULL else ~paste(format(z[,1],'%Y-%m-%d'), sprintf(value_fmt, z[,2]), sep='/'), 
                  hoverinfo = if (is.null(value_fmt)) NULL else 'text', ...);
    if (ncol(z) > 2)
        for (i in 3:ncol(z)) {
            width = line_width[1 + (i-2) %% length(line_width)];
            size = marker_size[1 + (i-2) %% length(marker_size)];
            res = res %>% add_trace(y = z[,i], mode = mode, color = I(colors[1 + (i-2) %% length(colors)]), 
                            line = if (width > 0) list(width = width) else NULL, 
                            marker = if (size > 0) list(size=size) else NULL,
                            name = colnames(z)[i], 
                            text = if (is.null(value_fmt)) NULL else ~paste(format(z[,1], date_fmt), sprintf(value_fmt, z[,i]), sep='/'), 
                            hoverinfo = if (is.null(value_fmt)) NULL else 'text', ...)
        }
    res %>% layout(xaxis=list(dtick = dtick, tickformat = date_fmt))
}

hist_ggplot = function(x, binwidth = 0.01, alpha = 1, ...) {
    y = lapply(1:NCOL(x), function(j) data.frame(y = as.numeric(x[,j]), class = j)) %>% bind_rows() %>% mutate(class = as.factor(class));
    ggplot(y[complete.cases(y),], aes(y, group=class, fill=class, ...)) + geom_histogram(position = 'identity', binwidth = binwidth, alpha = alpha)
}

CumReturns = function(R, wealth.index = FALSE, geometric = TRUE, begin = c("first", "axis")) 
{
    begin = begin[1]
    x = PerformanceAnalytics::checkData(R);
    columns = ncol(x)
    columnnames = colnames(x)
    one = 0
    if (!wealth.index) 
        one = 1
    if (begin == "first") {
        length.column.one = length(x[, 1])
        start.row = 1
        start.index = 0
        while (is.na(x[start.row, 1])) {
            start.row = start.row + 1
        }
        x = x[start.row:length.column.one, ]
        if (geometric) 
            reference.index = PerformanceAnalytics:::na.skip(x[, 1], FUN = function(x) {
                cumprod(1 + x)
            })
        else reference.index = PerformanceAnalytics:::na.skip(x[, 1], FUN = function(x) {
            cumsum(x)
        })
    }
    for (column in 1:columns) {
        if (begin == "axis") {
            start.index = FALSE
        }
        else {
            start.row = 1
            while (is.na(x[start.row, column])) {
                start.row = start.row + 1
            }
            start.index = ifelse(start.row > 1, TRUE, FALSE)
        }
        if (start.index) {
            if (geometric) 
                z = PerformanceAnalytics:::na.skip(x[, column], 
                    FUN = function(x, index = reference.index[(start.row - 1)]) {
                        rbind(index, 1 + x)
                    }
                )
            else z = PerformanceAnalytics:::na.skip(x[, column], 
                    FUN = function(x, index = reference.index[(start.row - 1)]) {
                        rbind(1 + index, 1 + x)
                    }
                )
        }
        else {
            z = 1 + x[, column]
        }
        column.Return.cumulative = PerformanceAnalytics:::na.skip(z, 
                    FUN = function(x, one, geometric) {
                        if (geometric) 
                            cumprod(x) - one
                        else (1 - one) + cumsum(x - 1)
                    }, one = one, geometric = geometric)
        if (column == 1) 
            Return.cumulative = column.Return.cumulative
        else Return.cumulative = merge(Return.cumulative, column.Return.cumulative)
    }
    if (columns == 1) 
        Return.cumulative = as.xts(Return.cumulative)
    colnames(Return.cumulative) = columnnames
    Return.cumulative
}

plotly.PerformanceSummary <- function(rtn.obj, geometric = TRUE, wealth.index = FALSE, begin = c("first", "axis"), main = "", 
                                         colors = c('#000000', '#0000FF', '#BF382A', '#0C4B8E'), date_breaks_freq = 12, date_breaks_fmt = "%Y-%m-%d", 
                                         value_fmt = NULL, line_width = 1, marker_size = 0)
{
    if (is.null(colnames(rtn.obj))) colnames(rtn.obj) = paste0('r', 1:ncol(rtn.obj));
    
    # Create function to calculate drawdowns
    dd.xts <- function(x, g = TRUE)
    {
        if(g == TRUE){y <- PerformanceAnalytics:::Drawdowns(na.omit(x))} else {y <- PerformanceAnalytics:::Drawdowns(n.omit(x), geometric = FALSE)}
        y
    }
    
    # a few extra bits to deal with the added rtn columns
    no.of.assets <- ncol(rtn.obj)
    asset.names <- colnames(rtn.obj)
    cr <- CumReturns(R = rtn.obj, wealth.index = wealth.index, geometric = geometric, begin = begin);
    dd <- do.call(merge, lapply(rtn.obj, dd.xts, geometric));
    colnames(dd) = asset.names;
    title.string <- main
    pcr = ts_plotly(cr, colors = colors, line_width = line_width, value_fmt = value_fmt[1]);
    pr = ts_plotly(100 * rtn.obj, colors = colors, line_width = line_width, showlegend = FALSE, value_fmt = value_fmt[1 + 2 %% length(value_fmt)]);
    pdd = ts_plotly(100 * dd, colors = colors, line_width = line_width, showlegend = FALSE, value_fmt = value_fmt[1 + 3 %% length(value_fmt)]);
    
    ly.xts <- subplot(list(pcr, pr, pdd), nrows = 3, shareX = TRUE, shareY = FALSE) %>% 
        layout(
            title = title.string,
            xaxis = list(dtick = paste0('M',date_breaks_freq), tickformat = if (is.null(date_breaks_fmt)) "%Y-%m-%d" else date_breaks_fmt)
        );
    
    ly.xts    
}

