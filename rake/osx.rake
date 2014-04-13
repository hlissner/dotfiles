
require_relative 'lib/output'

task :osx do
    echo "Applying OSX settings"
    sh 'chflags nohidden "${HOME}/Library"'
    sh 'defaults write NSGlobalDomain KeyRepeat -int 0'

    # Disable press-and-hold for keys in favor of key repeat
    sh 'defaults write ApplePressAndHoldEnabled -bool false'

    sh 'defaults write NSGlobalDomain AppleKeyboardUIMode -int 3'
    sh 'defaults write NSGlobalDomain AppleFontSmoothing -int 2'
    sh 'defaults write NSGlobalDomain AppleShowAllExtensions -bool true'
    sh 'defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true'
    sh 'defaults write com.apple.dock autohide -bool true'

    # Disable app quarantine
    sh 'defaults write com.apple.LaunchServices LSQuarantine -bool false'

    # Disable auto-correct
    sh 'defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false'

    # Avoid creating .DS_Store files on network volumes
    sh 'defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true'
    # Disable the warning when changing a file extension
    sh 'defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false'

    sh 'defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true'

    # Disable local Time Machine backups
    # sh 'hash tmutil &> /dev/null && sudo tmutil disablelocal'

    # Finder: allow text selection in Quick Look
    sh 'defaults write com.apple.finder QLEnableTextSelection -bool true'

    # When performing a search, search the current folder by default
    sh 'defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"'

    # Use column view
    sh 'defaults write com.apple.finder FXPreferredViewStyle -string "clmv"'

    sh 'defaults write com.apple.finder ShowStatusBar -bool true'
    sh 'defaults write com.apple.finder _FXShowPosixPathInTitle -bool true'

    sh 'killall Finder'
    sh 'killall Dock'
end
