#!/usr/bin/env bash

# KEEP
#gs -dSAFER -dBATCH -dNOPAUSE \
   #-sDEVICE=png16m -r300 \
   #-dTextAlphaBits=1 \
   #-dGraphicsAlphaBits=4 \
   #-dImageAlphaBits=4 \
   #-sOutputFile=raw.png ./base/sign.pdf
#convert raw.png -density 300 -gaussian-blur 0x0.6 -sigmoidal-contrast 7x50% -resize 480x800 -ordered-dither o4x4 -remap ./base/LUT6.png output.png

mkdir -p ./temp

# background only
echo "Render BG only..."
gs -dSAFER -dBATCH -dNOPAUSE \
  -sDEVICE=png16m \
  -dUseCropBox -dFitPage \
  -g480x800 \
  -dFILTERTEXT \
  -sOutputFile=./temp/img_480x800.png ./base/sign.pdf

# text only
echo "Render text only..."
gs -dSAFER -dBATCH -dNOPAUSE \
  -sDEVICE=pngalpha \
  -dUseCropBox -dFitPage \
  -g480x800 \
  -dFILTERIMAGE -dFILTERVECTOR \
  -dTextAlphaBits=1 -dGraphicsAlphaBits=1 \
  -dBackgroundColor=16#00000000 \
  -sOutputFile=./temp/text_480x800.png ./base/sign.pdf

echo "Dithering and quantizing background..."
convert ./temp/img_480x800.png \
   -gaussian-blur 0x0.6 -sigmoidal-contrast 7x60% \
   -ordered-dither o2x2 -remap ./base/LUT6.png \
   ./temp/bg_dither_6c.png

echo "Merging into final image..."
convert ./temp/bg_dither_6c.png ./temp/text_480x800.png -compose over -composite output.png
echo "Done!"

