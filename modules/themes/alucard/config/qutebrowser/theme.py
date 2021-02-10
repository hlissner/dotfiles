## Colors
palette = {
    'background': '#282a36',
    'background-alt': '#1E2029',
    'border': '#282a36',
    'current-line': '#44475a',
    'selection': '#44475a',
    'foreground': '#f8f8f2',
    'foreground-alt': '#e0e0e0',
    'foreground-attention': '#ffffff',
    'comment': '#6272a4',
    'cyan': '#8be9fd',
    'green': '#50fa7b',
    'orange': '#ffb86c',
    'pink': '#ff79c6',
    'purple': '#bd93f9',
    'red': '#ff5555',
    'yellow': '#f1fa8c'
}

spacing = {
    'vertical': 6,
    'horizontal': 4
}

padding = {
    'top': spacing['vertical'],
    'right': spacing['horizontal'],
    'bottom': spacing['vertical'],
    'left': spacing['horizontal']
}

# HACK This is set to mitigate the blinding flash of white in between page
#      loads. This can break sites with no explicit background, so I rely on the
#      let-there-be-light.user.js greasemonkey script to "reset" the background.
c.colors.webpage.bg = palette['background']

## UI
# Scrollbar style; much less intrusive than the default
c.scrolling.bar = "overlay"
# Completion
c.completion.shrink = True

## Fonts
c.fonts.default_family = "JetBrainsMono"
c.fonts.default_size = "10pt"

# Background color of the completion widget category headers.
c.colors.completion.category.bg = palette['background-alt']
# Bottom border color of the completion widget category headers.
c.colors.completion.category.border.bottom = palette['background-alt']
# Top border color of the completion widget category headers.
c.colors.completion.category.border.top = palette['border']
# Foreground color of completion widget category headers.
c.colors.completion.category.fg = palette['foreground']
# Background color of the completion widget for even rows.
c.colors.completion.even.bg = palette['background-alt']
# Background color of the completion widget for odd rows.
c.colors.completion.odd.bg = palette['background-alt']
# Text color of the completion widget.
c.colors.completion.fg = palette['foreground']
# Background color of the selected completion item.
c.colors.completion.item.selected.bg = palette['selection']
# Bottom border color of the selected completion item.
c.colors.completion.item.selected.border.bottom = palette['selection']
# Top border color of the completion widget category headers.
c.colors.completion.item.selected.border.top = palette['selection']
# Foreground color of the selected completion item.
c.colors.completion.item.selected.fg = palette['foreground']
# Foreground color of the matched text in the completion.
c.colors.completion.match.fg = palette['orange']
# Color of the scrollbar in completion view
c.colors.completion.scrollbar.bg = palette['background']
# Color of the scrollbar handle in completion view.
c.colors.completion.scrollbar.fg = palette['foreground']
# Background color for the download bar.
c.colors.downloads.bar.bg = palette['background-alt']
# Background color for downloads with errors.
c.colors.downloads.error.bg = palette['background-alt']
# Foreground color for downloads with errors.
c.colors.downloads.error.fg = palette['red']
# Color gradient stop for download backgrounds.
c.colors.downloads.stop.bg = palette['background-alt']

## Color gradient interpolation system for download backgrounds.
## Type: ColorSystem
## Valid values:
##   - rgb: Interpolate in the RGB color system.
##   - hsv: Interpolate in the HSV color system.
##   - hsl: Interpolate in the HSL color system.
##   - none: Don't show a gradient.
c.colors.downloads.system.bg = 'none'

## Background color for hints. Note that you can use a `rgba(...)` value
# for transparency.
c.colors.hints.bg = palette['background-alt']
# Font color for hints.
c.colors.hints.fg = palette['purple']
# Hints
c.hints.border = '1px solid ' + palette['background']
# Font color for the matched part of hints.
c.colors.hints.match.fg = palette['foreground-alt']
# Background color of the keyhint widget.
c.colors.keyhint.bg = palette['background-alt']
# Text color for the keyhint widget.
c.colors.keyhint.fg = palette['purple']
# Highlight color for keys to complete the current keychain.
c.colors.keyhint.suffix.fg = palette['selection']
# Background color of an error message.
c.colors.messages.error.bg = palette['background-alt']
# Border color of an error message.
c.colors.messages.error.border = palette['background']
# Foreground color of an error message.
c.colors.messages.error.fg = palette['red']
# Background color of an info message.
c.colors.messages.info.bg = palette['background-alt']
# Border color of an info message.
c.colors.messages.info.border = palette['background']
# Foreground color an info message.
c.colors.messages.info.fg = palette['comment']
# Background color of a warning message.
c.colors.messages.warning.bg = palette['background-alt']
# Border color of a warning message.
c.colors.messages.warning.border = palette['border']
# Foreground color a warning message.
c.colors.messages.warning.fg = palette['red']
# Background color for prompts.
c.colors.prompts.bg = palette['background-alt']
# Border used around UI elements in prompts.
c.colors.prompts.border = '1px solid ' + palette['background']
# Foreground color for prompts.
c.colors.prompts.fg = palette['cyan']
# Background color for the selected item in filename prompts.
c.colors.prompts.selected.bg = palette['selection']
# Background color of the statusbar in caret mode.
c.colors.statusbar.caret.bg = palette['background-alt']
# Foreground color of the statusbar in caret mode.
c.colors.statusbar.caret.fg = palette['orange']
# Background color of the statusbar in caret mode with a selection.
c.colors.statusbar.caret.selection.bg = palette['background-alt']
# Foreground color of the statusbar in caret mode with a selection.
c.colors.statusbar.caret.selection.fg = palette['orange']
# Background color of the statusbar in command mode.
c.colors.statusbar.command.bg = palette['background-alt']
# Foreground color of the statusbar in command mode.
c.colors.statusbar.command.fg = palette['pink']
# Background color of the statusbar in private browsing + command mode.
c.colors.statusbar.command.private.bg = palette['background-alt']
# Foreground color of the statusbar in private browsing + command mode.
c.colors.statusbar.command.private.fg = palette['foreground']
# Background color of the statusbar in insert mode.
c.colors.statusbar.insert.bg = palette['background-alt']
# Foreground color of the statusbar in insert mode.
c.colors.statusbar.insert.fg = palette['pink']
# Background color of the statusbar.
c.colors.statusbar.normal.bg = palette['background-alt']
# Foreground color of the statusbar.
c.colors.statusbar.normal.fg = palette['foreground-alt']
# Background color of the statusbar in passthrough mode.
c.colors.statusbar.passthrough.bg = palette['background']
# Foreground color of the statusbar in passthrough mode.
c.colors.statusbar.passthrough.fg = palette['orange']
# Background color of the statusbar in private browsing mode.
c.colors.statusbar.private.bg = palette['background-alt']
# Foreground color of the statusbar in private browsing mode.
c.colors.statusbar.private.fg = palette['foreground-alt']
# Background color of the progress bar.
c.colors.statusbar.progress.bg = palette['background-alt']
# Foreground color of the URL in the statusbar on error.
c.colors.statusbar.url.error.fg = palette['red']
# Default foreground color of the URL in the statusbar.
c.colors.statusbar.url.fg = palette['foreground']
# Foreground color of the URL in the statusbar for hovered links.
c.colors.statusbar.url.hover.fg = palette['cyan']
# Foreground color of the URL in the statusbar on successful load
c.colors.statusbar.url.success.http.fg = palette['green']
# Foreground color of the URL in the statusbar on successful load
c.colors.statusbar.url.success.https.fg = palette['green']
# Foreground color of the URL in the statusbar when there's a warning.
c.colors.statusbar.url.warn.fg = palette['yellow']
# Status bar padding
c.statusbar.padding = padding
# Background color of the tab bar.
c.colors.tabs.bar.bg = palette['background-alt']
# Background color of unselected even tabs.
c.colors.tabs.even.bg = palette['background-alt']
# Foreground color of unselected even tabs.
c.colors.tabs.even.fg = palette['comment']
# Color for the tab indicator on errors.
c.colors.tabs.indicator.error = palette['red']
# Color gradient start for the tab indicator.
c.colors.tabs.indicator.start = palette['orange']
# Color gradient end for the tab indicator.
c.colors.tabs.indicator.stop = palette['green']

## Color gradient interpolation system for the tab indicator.
## Type: ColorSystem
## Valid values:
##   - rgb: Interpolate in the RGB color system.
##   - hsv: Interpolate in the HSV color system.
##   - hsl: Interpolate in the HSL color system.
##   - none: Don't show a gradient.
c.colors.tabs.indicator.system = 'none'

# Background color of unselected odd tabs.
c.colors.tabs.odd.bg = palette['background-alt']
# Foreground color of unselected odd tabs.
c.colors.tabs.odd.fg = palette['comment']
# Background color of selected even tabs.
c.colors.tabs.selected.even.bg = palette['background']
# Foreground color of selected even tabs.
c.colors.tabs.selected.even.fg = palette['foreground']
# Background color of selected odd tabs.
c.colors.tabs.selected.odd.bg = palette['background']
# Foreground color of selected odd tabs.
c.colors.tabs.selected.odd.fg = palette['foreground']

## Tab padding
c.tabs.padding = padding
c.tabs.indicator.width = 1
c.tabs.favicons.scale = 1
