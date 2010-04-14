function frap = func_PureDiffusion (tList, Df, preProcess)


  ##  Assign parameters
  RNrel = preProcess{1};
  J1wxi = preProcess{2};
  alf2  = preProcess{3};
  U     = preProcess{4};


  ## Avoid assignment of physical irrelevant parameters by fitting routine
  if (Df < 0 || Df > 800)
    frap = -100*ones(size(tList));
    return
  endif


  ## Time points have to be stored in a a row vector
  if (rows(tList)!=1)
	  tList = tList';
  endif


  ## Calculate the FRAP recovery curve
  ea		= exp(-Df*alf2*tList);             # Exponential decay in Eq.(S.19)
  frap	= 2*(RNrel)*(U.*J1wxi)'*ea;        # Eq.(S.22)
  frap	= frap';                           # Transform to a column vector

endfunction
