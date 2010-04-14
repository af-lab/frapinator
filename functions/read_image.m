function image = read_image(file, extension, nFrames)

  if (strcmpi(extension,".tif") || strcmpi(extension,".tiff"))
    image = imread(file, 1:nFrames);
  elseif (strcmpi(extension,".lsm"))
    image = imread(file, 1:2:nFrames*2);
  endif

endfunction
