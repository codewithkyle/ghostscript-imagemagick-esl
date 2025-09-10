#!/usr/bin/env bash

PDF_FILE="$1"

if [ -z "$PDF_FILE" ]; then
  echo "Usage: ./run <pdf>"
  exit 1
fi

if [[ ! "$PDF_FILE" =~ \.pdf$|\.PDF$ ]]; then
  echo "Error: $PDF_FILE is not a PDF file."
  exit 1
fi

if [ ! -f "$PDF_FILE" ]; then
  echo "Error: File '$PDF_FILE' not found."
  exit 1
fi

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
  -sOutputFile=./temp/img_480x800.png "$PDF_FILE"

# text only
echo "Render text only..."
gs -dSAFER -dBATCH -dNOPAUSE \
  -sDEVICE=pngalpha \
  -dUseCropBox -dFitPage \
  -g480x800 \
  -dFILTERIMAGE -dFILTERVECTOR \
  -dTextAlphaBits=1 -dGraphicsAlphaBits=1 \
  -dBackgroundColor=16#00000000 \
  -sOutputFile=./temp/text_480x800.png "$PDF_FILE"

echo "Dithering and quantizing background..."
convert ./temp/img_480x800.png \
   -gaussian-blur 0x0.6 -sigmoidal-contrast 7x60% \
   -ordered-dither o2x2 -remap ./base/LUT6.png \
   ./temp/bg_dither_6c.png

echo "Extract alpha from text…"
convert ./temp/text_480x800.png \
  -alpha extract -colorspace Gray \
  +profile icc +profile icm -strip \
  -define png:color-type=0 \
  ./temp/text_alpha.png

echo "Quantize text colors without alpha…"
convert ./temp/text_480x800.png \
  -alpha off \
  -dither None \
  -remap ./base/LUT6.png \
  -colorspace sRGB -type TrueColor -define png:color-type=2 \
  +profile icc +profile icm -strip \
  ./temp/text_rgb_6c.png

echo "Restore alpha…"
convert ./temp/text_rgb_6c.png ./temp/text_alpha.png \
  -compose CopyOpacity -composite \
  PNG8:./temp/text_6c.png

echo "Merging into final image..."
convert ./temp/bg_dither_6c.png ./temp/text_6c.png -compose over -composite output.png
echo "Done!"

