function [f, fkon, fkoff, Df, iter] = fitter_FullModel_3parameters(bin_timestamps, bin_values, preProcess, ikon, ikoff, Df)


  flag_fit = 3;

  iParam = [ikon, ikoff, Df];
  func_FullModel_for_fit	= @(bin_timestamps, iParam) func_FullModel (bin_timestamps, iParam, preProcess, flag_fit);

  [f,fParam,kvg,iter,corp,covp,covr,stdresid,ci,r2] = leasqr (bin_timestamps, bin_values, iParam, func_FullModel_for_fit, 0.00000001, 200);

  fkon	= fParam(1);
  fkoff	= fParam(2);
  Df		= fParam(3);

endfunction
