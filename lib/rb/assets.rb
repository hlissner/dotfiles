# lib/assets.rb

# A library for retrieving file assets stored in my dotfiles.
module Assets
  DIRS = [
    "#{DOTFILES_THEME_DIR}/config/%s/%s",
    "#{DOTFILES_CONFIG_DIR}/%s/%s",
    "#{DOTFILES_CONFIG_DIR}/%s",
    "#{XDG_CONFIG_HOME}/%s/%s",
    "#{XDG_CONFIG_HOME}/%s"
  ].freeze

  # SFX_DIRS = [
  #   "#{DOTFILES_THEME_DIR}/sounds/%s",
  #   "#{DOTFILES_CONFIG_DIR}/rofi/sounds/%s"
  # ]

  # Return the path a existing icon living in my dotfiles.
  #
  # @param name [Symbol, String] The name (without file extension) or file
  #   name of an icon
  # @return [String, nil] The path to the icon file
  def self.icon(namespace, name)
    name ? _file(namespace, 'icons', name.to_s) : nil
  end

  # Return the path a existing Rofi theme.
  #
  # @param name [Symbol, String] The name (without file extension) or file
  #   name of a theme
  # @return [String, nil] The path to the theme file, nil otherwise
  def self.theme(namespace, name)
    return unless name
    name = "#{name}.rasi" if name.is_a?(Symbol)
    _file(namespace, 'themes', name.to_s)
  end

  # TODO
  # def self.sfx(namespace, name)
  #   return unless name
  #   _file('sounds', nil, "#{name}.ogg", dirs: SFX_DIRS)
  # end

  # TODO
  # def self.wallpaper(namespace, name)
  #   return unless name
  #   _file(namespace, 'wallpapers', name.to_s, "#{name}.png", "#{name}.jpg")
  # end

  # Return the first existing item of a type.
  #
  # @param type [Symbol] What type of asset to get (e.g. :theme or :icon)
  # @param args [Array<Symbol, String>] the names (no file extension) or file names of assets
  # @return [String, nil] The path to the asset, nil otherwise
  def self.find(namespace, type, *args)
    raise "Invalid asset type: #{type}" unless respond_to?(type)
    args.lazy.map { |a| public_send(type, namespace, a) }.find(&:itself)
  end

  protected
  def self._file(namespace, subdir, name, dirs: DIRS)
    dirs
      .lazy
      .map  { |dir|  File.expand_path("#{sprintf(dir, namespace.to_s, subdir)}/#{name}") }
      .find { |path| File.exist?(path) }
  end
end
