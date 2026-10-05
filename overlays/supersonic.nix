# overlays/supersonic.nix
#
# REVIEW: Report this upstream. `supersonic -rate-current N` tells the server,
#   but doesn't update itself unless I reload the entire library.

final: prev: {
  supersonic = prev.supersonic.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      (final.writeText "supersonic-ipc-rating.patch" ''
        --- a/backend/app.go
        +++ b/backend/app.go
        @@ -228,6 +228,7 @@
         							supportsRating.SetRating(mediaprovider.RatingFavoriteParameters{
         								TrackIDs: []string{tr.Metadata().ID},
         							}, rating)
        +							a.PlaybackManager.OnTrackRatingChanged(tr.Metadata().ID, rating)
         						}
         					}
         				}
      '')
    ];
  });
}
