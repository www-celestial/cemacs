SDL_VIDEODRIVER=dummy cesia run --allow ffi=SDL3,ffi=SDL3_ttf radius-bad.ce 2>&1 | head -1 | sed "s/^[^ ]* //"
