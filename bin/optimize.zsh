#!/usr/bin/env zsh
# Optimize images and PDF files (losslessly by default).
#
# SYNOPSIS:
#   optimize [-lh] FILES|DIRS...
#
# EXAMPLES:
#   optimize image.jpg image.png image.gif
#   optimize directory_of_images/
#   optimize directory_of_images/*.png
#
# DEPENDENCIES:
#   bc
#   PNGs: optipng, pngquant (lossy)
#   JPGs: jpegtran, jpegoptim (lossy)
#   GIFs: gifsicle
#   PDFs: ghostscript
#
#   All absent dependencies (except for bc) are auto-installed with
#   cached-nix-shell on demand, if needed.
#
# OPTIONS:
#  -l
#    Enable lossy compression.
#  -L
#    *Only* do lossy compression.

.filesize() { stat --printf="%s" "$1"; }

hey.requires bc
zparseopts -E -D -F -- l=lossy L=lossyonly o:=outdir || exit 1
# TODO: Support -o
[[ $lossyonly ]] && lossy=( -l )
for file in $@; do
  if [[ -d $file ]]; then
    hey.log "Traversing directory: $file..."
    ${0:a} $file/*
  elif [[ -f $file ]]; then
    hey.log "Processing file: $file..."
    local pre_size=$(.filesize "$file")
    case ${file:e} in
      png)
        [[ $lossy ]] && hey.do -! pngquant -f --ext .png --quality 90-98 $file
        [[ $lossyonly ]] || hey.do -! optipng -nc -nb -o7 $file
        ;;
      gif)
        hey.do -! gifsicle --batch --optimize=3 "$file"
        ;;
      jpg|jpeg)
        [[ $lossy ]] && hey.do -! jpegoptim --max=90 "$file"
        [[ $lossyonly ]] || hey.do -! jpegtran -copy none -optimize -progressive -outfile "$file" "$file"
        ;;
      pdf)
        # Adapted from Alfred Klomp's shrinkpdf script
        # <http://alfredklomp.com/programming/shrinkpdf/>
        local dpi=72
        hey.do -! -p ghostscript gs -q -dNOPAUSE -dBATCH -dSAFER \
          -sDEVICE=pdfwrite \
          -dPDFSETTINGS=/prepress \
          -dCompatibilityLevel=1.5 \
          -dEmbedAllFonts=true \
          -dSubsetFonts=true \
          -dAutoRotatePages=/None \
          -dMonoImageResolution=$dpi \
          -dMonoImageDownsampleType=/Bicubic \
          -dGrayImageResolution=$dpi \
          -dGrayImageDownsampleType=/Bicubic \
          -dColorImageResolution=$dpi \
          -dColorImageDownsampleType=/Bicubic \
          -sOutputFile="compressed_$file" \
          "$file" && mv -f "compressed_$file" "$file"
        ;;
      *)
        hey.warn "Unrecognized file: $file"
        ;;
    esac
    local post_size=$(.filesize "$file")
    local perc=$(echo "((${pre_size} - ${post_size}) / ${pre_size}) * 100" | bc -l)
    printf "* %s: %d => %d (%.2f%% reduction)\n" "$file" "$pre_size" "$post_size" "$perc"
  fi
done
