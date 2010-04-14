function koffT = fitter_FullModel_start_koff(valRec,tEnd,kon,preProcess)



  fTemp = @(koff)(frapTemp(koff,tEnd,kon,preProcess)-valRec);

  if (fTemp(10e+8) < 0)
    koffT = 10^4;
    disp("No good starting point determined. Maybe Df is too small?")
  else
    koffT = fzero(fTemp,[10e-8,10e+8]);
  endif


  ## Subfunction to calculate recovery value
  function recLevel = frapTemp(koff,tEnd,kon,preProcess)
  eps1	= 10^(-11);  #  Parameter for avoiding zero division and assuring right limiting process

  Df		= preProcess{1};
  J1wxi	= preProcess{2};
  alf2	= preProcess{3};
  E		= preProcess{4};

  Feq		= (koff+eps1)/(kon+koff+eps1);

  #- Modify E
  E		= Feq*E;          # Normalize with Feq

  ww		= 0.5*(Df*alf2+kon+koff);
  vv		= sqrt(ww.^2-koff*Df*alf2);

  bet		= ww+vv;
  gam		= ww-vv;

  AA		= -(0.5/koff)*(-ww-vv+koff).*(ww-vv)./vv;
  BB		= (0.5/koff)*(-ww+vv+koff).*(ww+vv)./vv;

  A		= AA.*E;
  B		= BB.*E;

  a		= kon*A./(-bet+koff);
  b		= kon*B./(-gam+koff+eps1);

  #- FRAP at t=0
  t			= 0;
  ea			= exp((-bet)*t);
  eb			= exp((-gam)*t);
  frapStart	= (((A+a).*J1wxi)'*ea+((B+b).*J1wxi)'*eb);

  #- FRAP at t=inf
  t			= 10^15;
  ea			= exp((-bet)*t);
  eb			= exp((-gam)*t);
  frapEnd		= (((A+a).*J1wxi)'*ea+((B+b).*J1wxi)'*eb);

  #- FRAP at tEnd
  t			= tEnd;
  ea			= exp((-bet)*t);
  eb			= exp((-gam)*t);
  frap		= (((A+a).*J1wxi)'*ea+((B+b).*J1wxi)'*eb);

  recLevel	= (frap-frapStart)/(frapEnd-frapStart);

endfunction
