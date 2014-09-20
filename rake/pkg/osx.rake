# coding: utf-8
require_relative '../lib/output'

desc "Set OSX default configuration"
task :osx do
  next unless is_mac?

  if system('defaults read com.apple.finder _FXShowPosixPathInTitle >&/dev/null')
    echo 'OSX settings already applied!'
    next
  end

  echo "Applying OSX settings"
  [
    'chflags nohidden "${HOME}/Library"',
    # 'defaults write NSGlobalDomain KeyRepeat -int 0',

    # Disable press-and-hold for keys in favor of key repeat
    'defaults write ApplePressAndHoldEnabled -bool false',

    'defaults write NSGlobalDomain AppleKeyboardUIMode -int 3',
    'defaults write NSGlobalDomain AppleFontSmoothing -int 2',
    'defaults write NSGlobalDomain AppleShowAllExtensions -bool true',
    'defaults write com.apple.dock autohide -bool true',

    # Expand save panel by default
    'defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true',
    'defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true',

    # Disable app quarantine
    'defaults write com.apple.LaunchServices LSQuarantine -bool false',

    # Disable auto-correct
    'defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false',

    # Disable smart quotes
    'defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false',
    # Disable smart dashes as they're annoying when typing code
    'defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false',

    # Avoid creating .DS_Store files on network volumes
    'defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true',
    # Disable the warning when changing a file extension
    'defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false',

    'defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true',

    # Disable local Time Machine backups
    # sh_safe 'hash_safe tmutil &> /dev/null && sudo tmutil disablelocal'
    # Prevent Time Machine from prompting to use new hard drives as backup volume
    'defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true',

    # Finder: allow text selection in Quick Look
    'defaults write com.apple.finder QLEnableTextSelection -bool true',

    # When performing a search, search the current folder by default
    'defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"',

    ### FINDER ###
    # Use column view
    'defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"', # default location for new finder windows
    'defaults write com.apple.finder FXPreferredViewStyle -string "clmv"',  # column view by default

    'defaults write com.apple.finder ShowPathbar -bool true',               # path bar
    'defaults write com.apple.finder ShowStatusBar -bool true',             # status bar
    'defaults write com.apple.finder _FXShowPosixPathInTitle -bool true',   # path in window title

    # Disable the warning before emptying the Trash
    'defaults write com.apple.finder WarnOnEmptyTrash -bool false',

    # Disable Dashboard
    'defaults write com.apple.dashboard mcx-disabled -bool true',
    # Don’t show Dashboard as a Space
    'defaults write com.apple.dock dashboard-in-overlay -bool true',

    # Make Dock icons of hidden applications translucent
    'defaults write com.apple.dock showhidden -bool true',

    # Disable Spotlight indexing for any volume that gets mounted and has not yet
    # been indexed before.
    # Use `sudo mdutil -i off "/Volumes/foo"` to stop indexing any volume.
    'sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"',

    ### Text edit ###
    # Use plain text mode for new TextEdit documents
    'defaults write com.apple.TextEdit RichText -int 0',
    # Open and save files as UTF-8 in TextEdit
    'defaults write com.apple.TextEdit PlainTextEncoding -int 4',
    'defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4',

    # Disable the sudden motion sensor as it’s not useful for SSDs
    'sudo pmset -a sms 0',

    # Load new settings before rebuilding the index
    'killall mds > /dev/null 2>&1',
    'killall Finder',
    'killall Dock'
  ].each { |cmd| sh_safe cmd }
end
