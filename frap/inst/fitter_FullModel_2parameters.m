## Copyright (C) 2008-2010 Florian Mueller
## Copyright (C) 2008-2010 Davide Mazza <shiner80@gmail.com>
## Copyright (C) 2010 Carnë Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

function [f, best_fkon, best_fkoff, fit_grid] = fitter_FullModel_2parameters(bin_timestamps, bin_values, preProcess)


  flag_fit  = 2;
  Df        = preProcess{1};

  konLogStart	= -4;
  konLogEnd	= 4;
  nStepsKon	= 40;
  konLog		= linspace(konLogStart,konLogEnd,nStepsKon);
  koffLog		= zeros(size(konLog));

  %- Determine recovery time to 90% for FRAP curve
  valRec	= 0.90;
  i90		= find( (bin_values-bin_values(1)) > valRec*(bin_values(end)-bin_values(1)),1,'first');
  t90		= bin_timestamps(i90);

  %- Find koff values and fit
  fit_grid = zeros(nStepsKon,6);

  kon = 0.04;
  koff = 0.01;
  for i = 1:nStepsKon

	  if (i !=1)
		  kon		= 10^konLog(i);
		  koff	= fitter_FullModel_start_koff (valRec,t90,kon,preProcess);
	  endif

	  koffLog(i)				= log10(koff);
	  iParam					= [kon, koff];

	  func_FullModel_for_fit	= @(bin_timestamps, iParam) func_FullModel (bin_timestamps, iParam, preProcess, flag_fit);

	  [f,fParam,kvg,iter,corp,covp,covr,stdresid,ci,r2] = leasqr (bin_timestamps, bin_values, iParam, func_FullModel_for_fit, 0.00000001, 200);


	  #FIXME code by me, using stdresid before hardcode ssr
  %	ssr						= sum(abs(stdresid));
	  #FIXME Hardcoded residuals to compare with fitting from nlinfit which gives plain vanilla residuals only
	  ssr = sum (abs(f-bin_values).^2);

  #	parFit_Summary(i,:)		= [kon koff parFit(1) ci(1,:) parFit(2) ci(2,:) ssr];
	  fit_grid(i,:)			= [iParam(1) iParam(2) fParam(1) fParam(2) Df ssr];
  endfor

  fit_grid	= sortrows(fit_grid, 6);
  best_fkon	= fit_grid(1,3);
  best_fkoff	= fit_grid(1,4);

  f = func_FullModel(bin_timestamps, [best_fkon, best_fkoff], preProcess, flag_fit);


endfunction
