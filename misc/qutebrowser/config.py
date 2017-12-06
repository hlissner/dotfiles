import os

# c.confirm_quit = ['never']

c.editor.command = [os.environ['EDITOR'], '-f', '{}']

# c.colors.completion.category.fg = 'white'
c.colors.completion.category.bg = '#343537'
# c.colors.completion.category.border.bottom = 'black'
c.colors.completion.category.border.top = '#343537'
# c.colors.completion.fg = 'white'
c.colors.completion.even.bg = '#141517'
c.colors.completion.odd.bg = c.colors.completion.even.bg
c.colors.completion.item.selected.fg = 'white'
c.colors.completion.item.selected.bg = '#545557'
# c.colors.completion.item.selected.border.bottom = '#bbbb00'
c.colors.completion.item.selected.border.top = '#545557'
c.colors.completion.match.fg = '#b5bd68'
c.colors.completion.scrollbar.fg = '#343537'
# c.colors.completion.scrollbar.bg = '#333333'
# c.colors.downloads.bar.bg = 'black'
# c.colors.downloads.error.bg = 'red'
# c.colors.downloads.error.fg = 'white'
# c.colors.downloads.start.bg = '#0000aa'
# c.colors.downloads.start.fg = 'white'
# c.colors.downloads.stop.bg = '#00aa00'
# c.colors.downloads.stop.fg = 'white'
# c.colors.downloads.system.bg = 'rgb'
# c.colors.downloads.system.fg = 'rgb'

c.colors.hints.bg = '#18191b'
c.colors.hints.fg = '#ffffff'
c.colors.hints.match.fg = '#b5bd68'

# c.colors.keyhint.fg = '#FFFFFF'
# c.colors.keyhint.bg = 'rgba(0, 0, 0, 80%)'
# c.colors.keyhint.suffix.fg = '#FFFF00'

# c.colors.messages.error.fg = 'white'
# c.colors.messages.error.bg = 'red'
# c.colors.messages.error.border = '#bb0000'

# c.colors.messages.info.fg = 'white'
# c.colors.messages.info.bg = 'black'
# c.colors.messages.info.border = '#333333'

# c.colors.messages.warning.fg = 'white'
# c.colors.messages.warning.bg = 'darkorange'
# c.colors.messages.warning.border = '#d47300'

# c.colors.prompts.bg = '#444444'
# c.colors.prompts.fg = 'white'
# c.colors.prompts.selected.bg = 'grey'
# c.colors.prompts.border = '1px solid gray'

c.statusbar.padding = {'top': 4, 'bottom': 4, 'left': 4, 'right': 4}
# c.colors.statusbar.caret.bg = 'purple'
# c.colors.statusbar.caret.fg = 'white'
# c.colors.statusbar.caret.selection.bg = '#a12dff'
# c.colors.statusbar.caret.selection.fg = 'white'
c.colors.statusbar.command.bg = '#1a1b1d'
# c.colors.statusbar.command.fg = 'white'
# c.colors.statusbar.command.private.bg = 'grey'
# c.colors.statusbar.command.private.fg = 'white'
c.colors.statusbar.normal.bg = '#1a1b1d'
# c.colors.statusbar.normal.fg = 'white'
c.colors.statusbar.insert.bg = 'darkgreen'
# c.colors.statusbar.insert.fg = 'white'
c.colors.statusbar.private.bg = '#2a8fed'
# c.colors.statusbar.private.fg = 'white'
# c.colors.statusbar.progress.bg = 'white'
# c.colors.statusbar.url.fg = 'white'
c.colors.statusbar.url.success.http.fg = '#b5bd68'
c.colors.statusbar.url.success.https.fg = '#bc77a8'
c.colors.statusbar.url.error.fg = '#cc6666'
c.colors.statusbar.url.warn.fg = '#f0c674'
c.colors.statusbar.url.hover.fg = '#8abeb7'

c.colors.tabs.even.bg = c.colors.statusbar.command.bg
c.colors.tabs.even.fg = 'white'
c.colors.tabs.odd.bg = c.colors.statusbar.command.bg
c.colors.tabs.odd.fg = 'white'
c.colors.tabs.selected.even.bg = '#38393b'
c.colors.tabs.selected.even.fg = c.colors.statusbar.command.fg
c.colors.tabs.selected.odd.bg = c.colors.tabs.selected.even.bg
c.colors.tabs.selected.odd.fg = c.colors.tabs.selected.even.fg
# c.colors.tabs.indicator.error = '#ff0000'
# c.colors.tabs.indicator.start = '#0000aa'
# c.colors.tabs.indicator.stop = '#00aa00'
# c.colors.tabs.indicator.system = 'rgb'
# c.colors.webpage.bg = 'white'

c.completion.height = '40%'
c.completion.web_history_max_items = 2500
# c.completion.cmd_history_max_items = 100
# c.completion.quick = True
# c.completion.scrollbar.padding = 2
# c.completion.scrollbar.width = 12
# c.completion.show = 'always'
# c.completion.shrink = False
# c.completion.timestamp_format = '%Y-%m-%d'
# c.completion.web_history_max_items = -1

c.content.default_encoding = 'utf-8'
# c.content.developer_extras = True
c.content.javascript.enabled = True
c.content.local_storage = True
# c.content.notifications = 'false'
# c.content.pdfjs = False
c.content.plugins = True
# c.content.cache.appcache = True
# c.content.cache.maximum_pages = 0
# c.content.cache.size = None
# c.content.cookies.accept = 'no-3rdparty'
# c.content.cookies.store = True
# c.content.dns_prefetch = True
# c.content.frame_flattening = False
# c.content.geolocation = 'ask'
# c.content.headers.accept_language = 'en-US,en'
# c.content.headers.custom = {}
# c.content.headers.do_not_track = True
# c.content.headers.referer = 'same-domain'
# c.content.headers.user_agent = None
# c.content.host_blocking.enabled = True
# c.content.host_blocking.lists = ['https://www.malwaredomainlist.com/hostslist/hosts.txt', 'http://someonewhocares.org/hosts/hosts', 'http://winhelp2002.mvps.org/hosts.zip', 'http://malwaredomains.lehigh.edu/files/justdomains.zip', 'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext']
# c.content.host_blocking.whitelist = ['piwik.org']
# c.content.hyperlink_auditing = False
# c.content.images = True
# c.content.javascript.alert = True
# c.content.javascript.can_access_clipboard = False
# c.content.javascript.can_close_tabs = False
# c.content.javascript.can_open_tabs_automatically = False
# c.content.javascript.log = {'unknown': 'debug', 'info': 'debug', 'warning': 'debug', 'error': 'debug'}
# c.content.javascript.modal_dialog = False
# c.content.javascript.prompt = True
# c.content.local_content_can_access_file_urls = True
# c.content.local_content_can_access_remote_urls = False
# c.content.media_capture = 'ask'
# c.content.netrc_file = None
# c.content.print_element_backgrounds = True
# c.content.private_browsing = False
# c.content.proxy = 'system'
# c.content.proxy_dns_requests = True
# c.content.ssl_strict = 'ask'
# c.content.user_stylesheets = []
# c.content.webgl = True
# c.content.xss_auditing = False

c.downloads.position = 'top'
# c.downloads.location.directory = None
# c.downloads.location.prompt = True
# c.downloads.location.remember = True
# c.downloads.location.suggestion = 'path'
# c.downloads.open_dispatcher = None

c.editor.encoding = 'utf-8'

# c.fonts.completion.category = 'bold 8pt monospace'
# c.fonts.completion.entry = '8pt monospace'
# c.fonts.debug_console = '8pt monospace'
# c.fonts.downloads = '8pt monospace'
# c.fonts.hints = 'bold 10pt monospace'
# c.fonts.keyhint = '8pt monospace'
# c.fonts.messages.error = '8pt monospace'
# c.fonts.messages.info = '8pt monospace'
# c.fonts.messages.warning = '8pt monospace'
# c.fonts.monospace = '"xos4 Terminus", Terminus, Monospace, "DejaVu Sans Mono", Monaco, "Bitstream Vera Sans Mono", "Andale Mono", "Courier New", Courier, "Liberation Mono", monospace, Fixed, Consolas, Terminal'
# c.fonts.prompts = '8pt sans-serif'
# c.fonts.statusbar = '8pt monospace'
# c.fonts.tabs = '8pt monospace'
# c.fonts.web.family.cursive = ''
# c.fonts.web.family.fantasy = ''
# c.fonts.web.family.fixed = ''
# c.fonts.web.family.sans_serif = ''
# c.fonts.web.family.serif = ''
# c.fonts.web.family.standard = ''
# c.fonts.web.size.default = 16
# c.fonts.web.size.default_fixed = 13
# c.fonts.web.size.minimum = 0
# c.fonts.web.size.minimum_logical = 6

# c.hints.auto_follow = 'unique-match'
# c.hints.auto_follow_timeout = 0
c.hints.border = '6px solid #18191b'
# c.hints.chars = 'asdfghjkl'
# c.hints.dictionary = '/usr/share/dict/words'
# c.hints.find_implementation = 'python'
# c.hints.hide_unmatched_rapid_hints = True
# c.hints.min_chars = 1
# c.hints.mode = 'letter'
# c.hints.next_regexes = ['\\bnext\\b', '\\bmore\\b', '\\bnewer\\b', '\\b[>→≫]\\b', '\\b(>>|»)\\b', '\\bcontinue\\b']
# c.hints.prev_regexes = ['\\bprev(ious)?\\b', '\\bback\\b', '\\bolder\\b', '\\b[<←≪]\\b', '\\b(<<|«)\\b']
# c.hints.scatter = True
# c.hints.uppercase = False


## Options
# c.history_gap_interval = 30
# c.ignore_case = 'smart'
# c.input.forward_unbound_keys = 'auto'
# c.input.insert_mode.auto_leave = True
# c.input.insert_mode.auto_load = False
# c.input.insert_mode.plugins = False
# c.input.links_included_in_focus_chain = True
# c.input.partial_timeout = 5000
# c.input.rocker_gestures = False
# c.input.spatial_navigation = False
# c.keyhint.blacklist = []
# c.keyhint.delay = 500
# c.messages.timeout = 2000
# c.messages.unfocused = False
# c.new_instance_open_target = 'tab'
# c.new_instance_open_target_window = 'last-focused'
# c.prompt.filebrowser = True
# c.prompt.radius = 8
# c.qt.args = []
# c.qt.force_platform = None
# c.qt.force_software_rendering = False
# c.scrolling.bar = False
c.scrolling.smooth = False
# c.session_default_name = None
# c.spellcheck.languages = []

# c.statusbar.hide = False
# c.statusbar.position = 'bottom'

c.tabs.background = True
c.tabs.padding = {'top': 4, 'bottom': 4, 'left': 4, 'right': 4}
c.tabs.indicator_padding = {'top': 5, 'bottom': 5, 'left': 0, 'right': 4}
c.tabs.mousewheel_switching = False
# c.tabs.close_mouse_button = 'middle'
# c.tabs.favicons.scale = 1.0
# c.tabs.favicons.show = True
# c.tabs.last_close = 'ignore'
# c.tabs.new_position.related = 'next'
# c.tabs.new_position.unrelated = 'last'
# c.tabs.position = 'top'
# c.tabs.select_on_remove = 'next'
c.tabs.show = 'multiple'
# c.tabs.show_switching_delay = 800
# c.tabs.tabs_are_windows = False
# c.tabs.title.alignment = 'left'
# c.tabs.title.format = '{index}: {title}'
# c.tabs.title.format_pinned = '{index}'
# c.tabs.width.bar = '20%'
# c.tabs.width.indicator = 3
# c.tabs.wrap = True

# c.url.auto_search = 'naive'
# c.url.default_page = 'https://start.duckduckgo.com/'
# c.url.incdec_segments = ['path', 'query']
# c.url.searchengines = {'DEFAULT': 'https://duckduckgo.com/?q={}'}
# c.url.start_pages = ['https://start.duckduckgo.com']
# c.url.yank_ignored_parameters = ['ref', 'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content']

# c.window.hide_wayland_decoration = False
# c.window.title_format = '{perc}{title}{title_sep}qutebrowser'

# c.zoom.default = '100%'
# c.zoom.levels = ['25%', '33%', '50%', '67%', '75%', '90%', '100%', '110%', '125%', '150%', '175%', '200%', '250%', '300%', '400%', '500%']
# c.zoom.mouse_divider = 512
# c.zoom.text_only = False


## Keybindings
config.bind(',v', 'spawn mpv {url}')
config.bind(';M', 'hint links spawn mpv {hint-url}')

## Bindings for normal mode
# config.bind("'", 'enter-mode jump_mark')
# config.bind('+', 'zoom-in')
# config.bind('-', 'zoom-out')
# config.bind('.', 'repeat-command')
# config.bind('/', 'set-cmd-text /')
# config.bind(':', 'set-cmd-text :')
# config.bind(';I', 'hint images tab')
# config.bind(';O', 'hint links fill :open -t -r {hint-url}')
# config.bind(';R', 'hint --rapid links window')
# config.bind(';Y', 'hint links yank-primary')
# config.bind(';b', 'hint all tab-bg')
# config.bind(';d', 'hint links download')
# config.bind(';f', 'hint all tab-fg')
# config.bind(';h', 'hint all hover')
# config.bind(';i', 'hint images')
# config.bind(';o', 'hint links fill :open {hint-url}')
# config.bind(';r', 'hint --rapid links tab-bg')
# config.bind(';t', 'hint inputs')
# config.bind(';y', 'hint links yank')
# config.bind('<Alt-1>', 'tab-focus 1')
# config.bind('<Alt-2>', 'tab-focus 2')
# config.bind('<Alt-3>', 'tab-focus 3')
# config.bind('<Alt-4>', 'tab-focus 4')
# config.bind('<Alt-5>', 'tab-focus 5')
# config.bind('<Alt-6>', 'tab-focus 6')
# config.bind('<Alt-7>', 'tab-focus 7')
# config.bind('<Alt-8>', 'tab-focus 8')
# config.bind('<Alt-9>', 'tab-focus -1')
# config.bind('<Ctrl-A>', 'navigate increment')
# config.bind('<Ctrl-Alt-p>', 'print')
# config.bind('<Ctrl-B>', 'scroll-page 0 -1')
# config.bind('<Ctrl-D>', 'scroll-page 0 0.5')
# config.bind('<Ctrl-F5>', 'reload -f')
# config.bind('<Ctrl-F>', 'scroll-page 0 1')
# config.bind('<Ctrl-N>', 'open -w')
# config.bind('<Ctrl-PgDown>', 'tab-next')
# config.bind('<Ctrl-PgUp>', 'tab-prev')
# config.bind('<Ctrl-Q>', 'quit')
# config.bind('<Ctrl-Return>', 'follow-selected -t')
# config.bind('<Ctrl-Shift-N>', 'open -p')
# config.bind('<Ctrl-Shift-T>', 'undo')
# config.bind('<Ctrl-Shift-W>', 'close')
# config.bind('<Ctrl-T>', 'open -t')
# config.bind('<Ctrl-Tab>', 'tab-focus last')
# config.bind('<Ctrl-U>', 'scroll-page 0 -0.5')
# config.bind('<Ctrl-V>', 'enter-mode passthrough')
# config.bind('<Ctrl-W>', 'tab-close')
# config.bind('<Ctrl-X>', 'navigate decrement')
# config.bind('<Ctrl-^>', 'tab-focus last')
# config.bind('<Ctrl-h>', 'home')
# config.bind('<Ctrl-p>', 'tab-pin')
# config.bind('<Ctrl-s>', 'stop')
# config.bind('<Escape>', 'clear-keychain ;; search ;; fullscreen --leave')
# config.bind('<F11>', 'fullscreen')
# config.bind('<F5>', 'reload')
# config.bind('<Return>', 'follow-selected')
# config.bind('<back>', 'back')
# config.bind('<forward>', 'forward')
# config.bind('=', 'zoom')
# config.bind('?', 'set-cmd-text ?')
# config.bind('@', 'run-macro')
# config.bind('B', 'set-cmd-text -s :quickmark-load -t')
# config.bind('D', 'tab-close -o')
# config.bind('F', 'hint all tab')
# config.bind('G', 'scroll-to-perc')
# config.bind('H', 'back')
# config.bind('J', 'tab-next')
# config.bind('K', 'tab-prev')
# config.bind('L', 'forward')
# config.bind('M', 'bookmark-add')
# config.bind('N', 'search-prev')
# config.bind('O', 'set-cmd-text -s :open -t')
# config.bind('PP', 'open -t -- {primary}')
# config.bind('Pp', 'open -t -- {clipboard}')
# config.bind('R', 'reload -f')
# config.bind('Sb', 'open qute://bookmarks#bookmarks')
# config.bind('Sh', 'open qute://history')
# config.bind('Sq', 'open qute://bookmarks')
# config.bind('Ss', 'open qute://settings')
# config.bind('T', 'tab-focus')
# config.bind('ZQ', 'quit')
# config.bind('ZZ', 'quit --save')
# config.bind('[[', 'navigate prev')
# config.bind(']]', 'navigate next')
# config.bind('`', 'enter-mode set_mark')
# config.bind('ad', 'download-cancel')
# config.bind('b', 'set-cmd-text -s :quickmark-load')
# config.bind('cd', 'download-clear')
# config.bind('co', 'tab-only')
# config.bind('d', 'tab-close')
# config.bind('f', 'hint')
# config.bind('g$', 'tab-focus -1')
# config.bind('g0', 'tab-focus 1')
# config.bind('gB', 'set-cmd-text -s :bookmark-load -t')
# config.bind('gC', 'tab-clone')
# config.bind('gO', 'set-cmd-text :open -t -r {url:pretty}')
# config.bind('gU', 'navigate up -t')
# config.bind('g^', 'tab-focus 1')
# config.bind('ga', 'open -t')
# config.bind('gb', 'set-cmd-text -s :bookmark-load')
# config.bind('gd', 'download')
# config.bind('gf', 'view-source')
# config.bind('gg', 'scroll-to-perc 0')
# config.bind('gl', 'tab-move -')
# config.bind('gm', 'tab-move')
# config.bind('go', 'set-cmd-text :open {url:pretty}')
# config.bind('gr', 'tab-move +')
# config.bind('gt', 'set-cmd-text -s :buffer')
# config.bind('gu', 'navigate up')
# config.bind('h', 'scroll left')
# config.bind('i', 'enter-mode insert')
# config.bind('j', 'scroll down')
# config.bind('k', 'scroll up')
# config.bind('l', 'scroll right')
# config.bind('m', 'quickmark-save')
# config.bind('n', 'search-next')
# config.bind('o', 'set-cmd-text -s :open')
# config.bind('pP', 'open -- {primary}')
# config.bind('pp', 'open -- {clipboard}')
# config.bind('q', 'record-macro')
# config.bind('r', 'reload')
# config.bind('sf', 'save')
# config.bind('sk', 'set-cmd-text -s :bind')
# config.bind('sl', 'set-cmd-text -s :set -t')
# config.bind('ss', 'set-cmd-text -s :set')
# config.bind('th', 'back -t')
# config.bind('tl', 'forward -t')
# config.bind('u', 'undo')
# config.bind('v', 'enter-mode caret')
# config.bind('wB', 'set-cmd-text -s :bookmark-load -w')
# config.bind('wO', 'set-cmd-text :open -w {url:pretty}')
# config.bind('wP', 'open -w -- {primary}')
# config.bind('wb', 'set-cmd-text -s :quickmark-load -w')
# config.bind('wf', 'hint all window')
# config.bind('wh', 'back -w')
# config.bind('wi', 'inspector')
# config.bind('wl', 'forward -w')
# config.bind('wo', 'set-cmd-text -s :open -w')
# config.bind('wp', 'open -w -- {clipboard}')
# config.bind('xO', 'set-cmd-text :open -b -r {url:pretty}')
# config.bind('xb', 'config-cycle statusbar.hide')
# config.bind('xo', 'set-cmd-text -s :open -b')
# config.bind('xt', 'config-cycle tabs.show always switching')
# config.bind('xx', 'config-cycle statusbar.hide ;; config-cycle tabs.show always switching')
# config.bind('yD', 'yank domain -s')
# config.bind('yP', 'yank pretty-url -s')
# config.bind('yT', 'yank title -s')
# config.bind('yY', 'yank -s')
# config.bind('yd', 'yank domain')
# config.bind('yp', 'yank pretty-url')
# config.bind('yt', 'yank title')
# config.bind('yy', 'yank')
# config.bind('{{', 'navigate prev -t')
# config.bind('}}', 'navigate next -t')

## Bindings for caret mode
# config.bind('$', 'move-to-end-of-line', mode='caret')
# config.bind('0', 'move-to-start-of-line', mode='caret')
# config.bind('<Ctrl-Space>', 'drop-selection', mode='caret')
# config.bind('<Escape>', 'leave-mode', mode='caret')
# config.bind('<Return>', 'yank selection', mode='caret')
# config.bind('<Space>', 'toggle-selection', mode='caret')
# config.bind('G', 'move-to-end-of-document', mode='caret')
# config.bind('H', 'scroll left', mode='caret')
# config.bind('J', 'scroll down', mode='caret')
# config.bind('K', 'scroll up', mode='caret')
# config.bind('L', 'scroll right', mode='caret')
# config.bind('Y', 'yank selection -s', mode='caret')
# config.bind('[', 'move-to-start-of-prev-block', mode='caret')
# config.bind(']', 'move-to-start-of-next-block', mode='caret')
# config.bind('b', 'move-to-prev-word', mode='caret')
# config.bind('c', 'enter-mode normal', mode='caret')
# config.bind('e', 'move-to-end-of-word', mode='caret')
# config.bind('gg', 'move-to-start-of-document', mode='caret')
# config.bind('h', 'move-to-prev-char', mode='caret')
# config.bind('j', 'move-to-next-line', mode='caret')
# config.bind('k', 'move-to-prev-line', mode='caret')
# config.bind('l', 'move-to-next-char', mode='caret')
# config.bind('v', 'toggle-selection', mode='caret')
# config.bind('w', 'move-to-next-word', mode='caret')
# config.bind('y', 'yank selection', mode='caret')
# config.bind('{', 'move-to-end-of-prev-block', mode='caret')
# config.bind('}', 'move-to-end-of-next-block', mode='caret')

## Bindings for command mode
# config.bind('<Alt-B>', 'rl-backward-word', mode='command')
# config.bind('<Alt-Backspace>', 'rl-backward-kill-word', mode='command')
# config.bind('<Alt-D>', 'rl-kill-word', mode='command')
# config.bind('<Alt-F>', 'rl-forward-word', mode='command')
# config.bind('<Ctrl-?>', 'rl-delete-char', mode='command')
# config.bind('<Ctrl-A>', 'rl-beginning-of-line', mode='command')
# config.bind('<Ctrl-B>', 'rl-backward-char', mode='command')
# config.bind('<Ctrl-D>', 'completion-item-del', mode='command')
# config.bind('<Ctrl-E>', 'rl-end-of-line', mode='command')
# config.bind('<Ctrl-F>', 'rl-forward-char', mode='command')
# config.bind('<Ctrl-H>', 'rl-backward-delete-char', mode='command')
# config.bind('<Ctrl-K>', 'rl-kill-line', mode='command')
# config.bind('<Ctrl-N>', 'command-history-next', mode='command')
# config.bind('<Ctrl-P>', 'command-history-prev', mode='command')
# config.bind('<Ctrl-Shift-Tab>', 'completion-item-focus prev-category', mode='command')
# config.bind('<Ctrl-Tab>', 'completion-item-focus next-category', mode='command')
# config.bind('<Ctrl-U>', 'rl-unix-line-discard', mode='command')
# config.bind('<Ctrl-W>', 'rl-unix-word-rubout', mode='command')
# config.bind('<Ctrl-Y>', 'rl-yank', mode='command')
# config.bind('<Down>', 'command-history-next', mode='command')
# config.bind('<Escape>', 'leave-mode', mode='command')
# config.bind('<Return>', 'command-accept', mode='command')
# config.bind('<Shift-Delete>', 'completion-item-del', mode='command')
# config.bind('<Shift-Tab>', 'completion-item-focus prev', mode='command')
# config.bind('<Tab>', 'completion-item-focus next', mode='command')
# config.bind('<Up>', 'command-history-prev', mode='command')

## Bindings for hint mode
# config.bind('<Ctrl-B>', 'hint all tab-bg', mode='hint')
# config.bind('<Ctrl-F>', 'hint links', mode='hint')
# config.bind('<Ctrl-R>', 'hint --rapid links tab-bg', mode='hint')
# config.bind('<Escape>', 'leave-mode', mode='hint')
# config.bind('<Return>', 'follow-hint', mode='hint')

## Bindings for insert mode
# config.bind('<Ctrl-E>', 'open-editor', mode='insert')
# config.bind('<Escape>', 'leave-mode', mode='insert')
# config.bind('<Shift-Ins>', 'insert-text {primary}', mode='insert')

## Bindings for passthrough mode
# config.bind('<Ctrl-V>', 'leave-mode', mode='passthrough')

## Bindings for prompt mode
# config.bind('<Alt-B>', 'rl-backward-word', mode='prompt')
# config.bind('<Alt-Backspace>', 'rl-backward-kill-word', mode='prompt')
# config.bind('<Alt-D>', 'rl-kill-word', mode='prompt')
# config.bind('<Alt-F>', 'rl-forward-word', mode='prompt')
# config.bind('<Ctrl-?>', 'rl-delete-char', mode='prompt')
# config.bind('<Ctrl-A>', 'rl-beginning-of-line', mode='prompt')
# config.bind('<Ctrl-B>', 'rl-backward-char', mode='prompt')
# config.bind('<Ctrl-E>', 'rl-end-of-line', mode='prompt')
# config.bind('<Ctrl-F>', 'rl-forward-char', mode='prompt')
# config.bind('<Ctrl-H>', 'rl-backward-delete-char', mode='prompt')
# config.bind('<Ctrl-K>', 'rl-kill-line', mode='prompt')
# config.bind('<Ctrl-U>', 'rl-unix-line-discard', mode='prompt')
# config.bind('<Ctrl-W>', 'rl-unix-word-rubout', mode='prompt')
# config.bind('<Ctrl-X>', 'prompt-open-download', mode='prompt')
# config.bind('<Ctrl-Y>', 'rl-yank', mode='prompt')
# config.bind('<Down>', 'prompt-item-focus next', mode='prompt')
# config.bind('<Escape>', 'leave-mode', mode='prompt')
# config.bind('<Return>', 'prompt-accept', mode='prompt')
# config.bind('<Shift-Tab>', 'prompt-item-focus prev', mode='prompt')
# config.bind('<Tab>', 'prompt-item-focus next', mode='prompt')
# config.bind('<Up>', 'prompt-item-focus prev', mode='prompt')
# config.bind('n', 'prompt-accept no', mode='prompt')
# config.bind('y', 'prompt-accept yes', mode='prompt')

## Bindings for register mode
# config.bind('<Escape>', 'leave-mode', mode='register')
