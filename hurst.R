# f - fraction of day when mkt closed
gk_volat = function(open, high, low, close, f = 0)
{
  H = log(high/open);
  L = log(low/open);
  C = log(close/open);
  sigma2 = 0.511 * (H-L)*(H-L) - 0.019 * (C * (H+L) - 2 * H * L) - 0.383 * C * C;
  if (f > 0 && f < 1) { # overnight
    OV = log(open / stats::lag(close));
    A = 0.12;
    sigma2 = A * OV * OV / f + (1-A) * sigma2;
   }
   sqrt(sigma2);
}

rolling_hurst_gk = function(x, look_back, method = 'lm', ...) {
    
    fcalc = function(y) {
        Vol = na.fill(y$GK, 0);
        Vol = sqrt(as.numeric(cumsum(Vol * Vol)));
        Vlm = as.numeric(cumsum(na.fill(y[,'volume'], 0)));
        if (tail(Vlm, 1) < 1) Vlm = seq(0, 1, length.out = nrow(y)) else Vlm = Vlm / tail(Vlm, 1);
        df = data.frame(y = log(Vol), x = log(Vlm)) %>% filter(is.finite(x), is.finite(y));
        H = if (nrow(df) > 10) coefficients(do.call(what = method, args = append(list(formula = y ~ x, data = df), list(...))))[2] else NaN;
        H
    }
    if (!('GK' %in% colnames(x))) x$GK = with(x, gk_volat(open, high, low, close));
    res = rollapplyr(x, width = look_back, by.column = FALSE, FUN = fcalc);
    res
}

