require_relative '../lib/output'

desc "Set OSX default configuration"
task :osx do
  next unless is_mac?

  if system('defaults read com.apple.finder _FXShowPosixPathInTitle >&/dev/null')
    echo 'OSX settings already applied!'
    next
  end

  echo "Applying OSX settings"
  sh_safe 'chflags nohidden "${HOME}/Library"'
  sh_safe 'defaults write NSGlobalDomain KeyRepeat -int 0'

  # Disable press-and-hold for keys in favor of key repeat
  sh_safe 'defaults write ApplePressAndHoldEnabled -bool false'

  sh_safe 'defaults write NSGlobalDomain AppleKeyboardUIMode -int 3'
  sh_safe 'defaults write NSGlobalDomain AppleFontSmoothing -int 2'
  sh_safe 'defaults write NSGlobalDomain AppleShowAllExtensions -bool true'
  sh_safe 'defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true'
  sh_safe 'defaults write com.apple.dock autohide -bool true'

  # Disable app quarantine
  sh_safe 'defaults write com.apple.LaunchServices LSQuarantine -bool false'

  # Disable auto-correct
  sh_safe 'defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false'

  # Avoid creating .DS_Store files on network volumes
  sh_safe 'defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true'
  # Disable the warning when changing a file extension
  sh_safe 'defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false'

  sh_safe 'defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true'

  # Disable local Time Machine backups
  # sh_safe 'hash_safe tmutil &> /dev/null && sudo tmutil disablelocal'

  # Finder: allow text selection in Quick Look
  sh_safe 'defaults write com.apple.finder QLEnableTextSelection -bool true'

  # When performing a search, search the current folder by default
  sh_safe 'defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"'

  # Use column view
  sh_safe 'defaults write com.apple.finder FXPreferredViewStyle -string "clmv"'

  sh_safe 'defaults write com.apple.finder ShowStatusBar -bool true'
  sh_safe 'defaults write com.apple.finder _FXShowPosixPathInTitle -bool true'

  sh_safe 'killall Finder'
  sh_safe 'killall Dock'
end
