# modules/desktop/media/video.nix --- the pictures. They move.
#
# For all things video. Video playback, (en|de)coding, and editing.  OBS to
# capture footage/stream, audacity for audio, handbrake/ffmpeg to encode it all.
# This, paired with DaVinci Resolve for video editing and I'm set for the
# occasional gameplay, instructional, or product demo video.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.media.video;
in {
  options.modules.desktop.media.video = {
    enable = mkBoolOpt false;
    player.enable = mkBoolOpt true;
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.player.enable {
      user.packages = with pkgs.unstable; [
        mpv
        mpvc  # CLI controller for mpv
        ffmpeg-full
        yt-dlp
      ];

      home.configFile."mpv/mpv.conf".text = ''
        profile=gpu-hq
        vo=gpu-next
        gpu-api=vulkan
        hwdec=auto-copy
        video-sync=display-resample
        interpolation=yes
        deband=yes
        save-position-on-quit=yes
        osc=no
        ytdl-format=bestvideo+bestaudio/best

        [image]
        profile-cond=path:match('%.jpe?g$') or path:match('%.png$') or path:match('%.webp$') or path:match('%.gif$')
        image-display-duration=inf
        loop-file=inf
      '';

      home.configFile."mpv/input.conf".text = ''
        MBTN_LEFT cycle pause
        WHEEL_UP seek 5
        WHEEL_DOWN seek -5
        Ctrl+o script-binding select/select-playlist
      '';

      xdg.mime.defaultApplications = {
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "image/png" = "mpv.desktop";
        "image/jpeg" = "mpv.desktop";
      };
    })
  ]);
}
