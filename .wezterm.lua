local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local IS_WINDOWS = wezterm.target_triple:find 'windows' ~= nil
local IS_DARWIN = wezterm.target_triple:find 'darwin' ~= nil
local HOME = (wezterm.home_dir or os.getenv 'HOME' or os.getenv 'USERPROFILE' or ''):gsub('\\', '/'):gsub('/$', '')

local TOKYO_NIGHT = {
  bg = '#1a1b26',
  surface = '#1f2335',
  surface_alt = '#24283b',
  border = '#3b4261',
  text = '#c0caf5',
  muted = '#7a88cf',
  accent = '#7aa2f7',
  accent_alt = '#bb9af7',
  success = '#9ece6a',
  warning = '#e0af68',
}

local HELP_SECTIONS = {
  {
    title = 'Windows / Tabs',
    entries = {
      { key = 'c', description = 'new tab' },
      { key = 'n / p', description = 'next / previous tab' },
      { key = 'l', description = 'last active tab' },
      { key = '0-9', description = 'jump to tab index' },
      { key = 'w', description = 'list tabs' },
      { key = '&', description = 'close current tab' },
    },
  },
  {
    title = 'Panes',
    entries = {
      { key = '%', description = 'split left/right' },
      { key = '"', description = 'split top/bottom' },
      { key = 'o', description = 'next pane' },
      { key = 'q', description = 'select pane by number' },
      { key = 'x', description = 'close pane' },
      { key = 'z', description = 'toggle zoom' },
      { key = '!', description = 'move pane to new tab' },
      { key = '{ / }', description = 'rotate panes' },
      { key = 'Arrow keys', description = 'move focus' },
      { key = 'Alt + Arrow keys', description = 'resize pane' },
    },
  },
  {
    title = 'Workspaces',
    entries = {
      { key = 's', description = 'list workspaces' },
      { key = '$', description = 'rename workspace' },
      { key = '( / )', description = 'previous / next workspace' },
    },
  },
  {
    title = 'Clipboard / Help',
    entries = {
      { key = '[', description = 'copy mode' },
      { key = ']', description = 'paste clipboard' },
      { key = 'h', description = 'open this help' },
      { key = 'b', description = 'send literal Ctrl+b' },
    },
  },
}

if IS_WINDOWS then
  table.insert(HELP_SECTIONS[1].entries, 2, { key = 't', description = 'shell launcher' })
end

local function file_exists(path)
  local handle = io.open(path, 'r')
  if handle then
    handle:close()
    return true
  end
  return false
end

local function push_spawn(menu, label, args, check_path)
  if check_path and not file_exists(check_path) then
    return
  end

  local entry = { label = label }
  if args then
    entry.args = args
  end

  table.insert(menu, entry)
end

local function first_existing_path(paths)
  for _, path in ipairs(paths) do
    if file_exists(path) then
      return path
    end
  end
  return nil
end

local get_cwd_uri
local path_from_uri

local function configure_platform(config)
  if IS_WINDOWS then
    local git_bash = 'C:\\Program Files\\Git\\bin\\bash.exe'
    config.default_prog = file_exists(git_bash) and { git_bash, '-i', '-l' } or { 'powershell.exe', '-NoLogo' }

    local launch_menu = {}
    push_spawn(launch_menu, 'Git Bash', { git_bash, '-i', '-l' }, git_bash)
    push_spawn(launch_menu, 'PowerShell Core', { 'pwsh.exe', '-NoLogo' })
    push_spawn(launch_menu, 'Windows PowerShell', { 'powershell.exe', '-NoLogo' })
    push_spawn(launch_menu, 'Command Prompt', { 'cmd.exe' })
    config.launch_menu = launch_menu
    return
  end

  local launch_menu = {}
  push_spawn(launch_menu, 'Default Shell')

  local zsh = first_existing_path { '/bin/zsh', '/usr/bin/zsh' }
  local bash = first_existing_path { '/bin/bash', '/usr/bin/bash', '/usr/local/bin/bash', '/opt/homebrew/bin/bash' }
  local fish = first_existing_path { '/usr/bin/fish', '/usr/local/bin/fish', '/opt/homebrew/bin/fish' }

  push_spawn(launch_menu, 'zsh', zsh and { zsh, '-l' } or nil, zsh)
  push_spawn(launch_menu, 'bash', bash and { bash, '-l' } or nil, bash)
  push_spawn(launch_menu, 'fish', fish and { fish, '-l' } or nil, fish)

  if #launch_menu > 0 then
    config.launch_menu = launch_menu
  end

  if IS_DARWIN then
    config.send_composed_key_when_left_alt_is_pressed = false
    config.send_composed_key_when_right_alt_is_pressed = false
  end
end

local function build_terminal_fonts()
  local fonts = {
    { family = 'JetBrains Mono', weight = 'Regular' },
    { family = 'Sarasa Mono K', weight = 'Regular' },
    { family = 'Sarasa Term K', weight = 'Regular' },
  }

  if IS_WINDOWS then
    table.insert(fonts, { family = 'Cascadia Mono', weight = 'Regular' })
    table.insert(fonts, { family = 'Consolas', weight = 'Regular' })
    table.insert(fonts, { family = 'Malgun Gothic', scale = 1.08 })
    table.insert(fonts, { family = 'Noto Sans KR', scale = 1.08 })
  elseif IS_DARWIN then
    table.insert(fonts, { family = 'Menlo', weight = 'Regular' })
    table.insert(fonts, { family = 'SF Mono', weight = 'Regular' })
    table.insert(fonts, { family = 'Apple SD Gothic Neo', scale = 1.08 })
    table.insert(fonts, { family = 'Noto Sans CJK KR', scale = 1.08 })
  else
    table.insert(fonts, { family = 'DejaVu Sans Mono', weight = 'Regular' })
    table.insert(fonts, { family = 'Liberation Mono', weight = 'Regular' })
    table.insert(fonts, { family = 'Noto Sans CJK KR', scale = 1.08 })
    table.insert(fonts, { family = 'Noto Sans KR', scale = 1.08 })
  end

  return fonts
end

local function build_window_frame_fonts()
  local fonts = {
    { family = 'JetBrains Mono', weight = 'Bold' },
    { family = 'Sarasa Mono K', weight = 'Bold' },
    { family = 'Sarasa Term K', weight = 'Bold' },
  }

  if IS_WINDOWS then
    table.insert(fonts, { family = 'Cascadia Mono', weight = 'Bold' })
    table.insert(fonts, { family = 'Consolas', weight = 'Bold' })
    table.insert(fonts, { family = 'Malgun Gothic', weight = 'Bold' })
  elseif IS_DARWIN then
    table.insert(fonts, { family = 'Menlo', weight = 'Regular' })
    table.insert(fonts, { family = 'SF Mono', weight = 'Regular' })
    table.insert(fonts, { family = 'Apple SD Gothic Neo', weight = 'Bold' })
  else
    table.insert(fonts, { family = 'DejaVu Sans Mono', weight = 'Bold' })
    table.insert(fonts, { family = 'Liberation Mono', weight = 'Bold' })
    table.insert(fonts, { family = 'Noto Sans CJK KR', weight = 'Bold' })
  end

  table.insert(fonts, { family = 'NanumSquare Neo', weight = 'Bold' })

  return fonts
end

local function current_spawn_cwd(pane)
  local cwd = path_from_uri(get_cwd_uri(pane))
  if cwd == '' then
    return nil
  end
  return cwd
end

local function windows_shell_specs()
  local specs = {}

  if not IS_WINDOWS then
    return specs
  end

  local git_bash = 'C:\\Program Files\\Git\\bin\\bash.exe'
  if file_exists(git_bash) then
    specs.gitbash = {
      label = 'Git Bash',
      args = { git_bash, '-i', '-l' },
    }
  end

  specs.powershell = {
    label = 'PowerShell',
    args = { 'powershell.exe', '-NoLogo' },
  }

  specs.cmd = {
    label = 'Command Prompt',
    args = { 'cmd.exe' },
  }

  return specs
end

local function spawn_command_for_pane(spec, pane)
  local command = {
    args = spec.args,
    domain = 'CurrentPaneDomain',
  }

  local cwd = current_spawn_cwd(pane)
  if cwd then
    command.cwd = cwd
  end

  return command
end

local function replace_pane_with_shell(window, pane, spec)
  if not pane or not spec then
    return
  end

  local new_pane = pane:split {
    direction = 'Bottom',
    size = 0.5,
    args = spec.args,
    cwd = current_spawn_cwd(pane),
    domain = 'CurrentPaneDomain',
  }

  if new_pane then
    new_pane:activate()
  end

  window:perform_action(act.CloseCurrentPane { confirm = false }, pane)
end

local function show_windows_shell_picker(window, pane)
  if not IS_WINDOWS then
    return
  end

  local specs = windows_shell_specs()
  local order = { 'gitbash', 'powershell', 'cmd' }
  local choices = {}

  for _, id in ipairs(order) do
    local spec = specs[id]
    if spec then
      table.insert(choices, {
        id = id .. ':newtab',
        label = spec.label .. ' (new tab)',
      })
      table.insert(choices, {
        id = id .. ':replace',
        label = spec.label .. ' (replace pane)',
      })
    end
  end

  window:perform_action(
    act.InputSelector {
      title = 'Launch shell',
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(win, target_pane, id)
        if not id then
          return
        end

        local shell_id, mode = id:match '^([^:]+):([^:]+)$'
        local target_spec = windows_shell_specs()[shell_id]
        if not target_spec then
          return
        end

        if mode == 'newtab' then
          win:perform_action(act.SpawnCommandInNewTab(spawn_command_for_pane(target_spec, target_pane)), target_pane)
          return
        end

        if mode == 'replace' then
          replace_pane_with_shell(win, target_pane, target_spec)
        end
      end),
    },
    pane
  )
end

local function build_mouse_bindings()
  local bindings = {
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = act.CompleteSelection 'Clipboard',
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
    },
    {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.Nop,
    },
    {
      event = { Down = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = act.PasteFrom 'Clipboard',
    },
    {
      event = { Down = { streak = 1, button = 'Middle' } },
      mods = 'NONE',
      action = act.PasteFrom 'Clipboard',
    },
  }

  if IS_DARWIN then
    table.insert(bindings, 4, {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'SUPER',
      action = act.OpenLinkAtMouseCursor,
    })
    table.insert(bindings, 5, {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'SUPER',
      action = act.Nop,
    })
  end

  return bindings
end

get_cwd_uri = function(source)
  if not source then
    return nil
  end

  local ok_getter, getter = pcall(function()
    return source.get_current_working_dir
  end)
  if ok_getter and type(getter) == 'function' then
    local ok, value = pcall(function()
      return getter(source)
    end)
    if ok then
      return value
    end
  end

  local ok_cwd, cwd = pcall(function()
    return source.current_working_dir
  end)
  if ok_cwd then
    return cwd
  end

  return nil
end

local function safe_field(source, field)
  if not source then
    return nil
  end

  local ok, value = pcall(function()
    return source[field]
  end)
  if ok then
    return value
  end
  return nil
end

local function normalize_path(path)
  if not path or path == '' then
    return ''
  end

  local normalized = path:gsub('\\', '/'):gsub('/$', '')
  normalized = normalized:gsub('^/([A-Za-z])/', function(drive)
    return drive:upper() .. ':/'
  end)

  return normalized
end

local function basename(path)
  local normalized = normalize_path(path)
  if normalized == '' then
    return ''
  end
  return normalized:match('([^/]+)$') or normalized
end

path_from_uri = function(uri)
  if not uri then
    return ''
  end

  local path = ''
  if type(uri) == 'userdata' or type(uri) == 'table' then
    path = safe_field(uri, 'file_path') or safe_field(uri, 'path') or ''
  elseif type(uri) == 'string' then
    if wezterm.url and type(wezterm.url.parse) == 'function' then
      local ok, parsed = pcall(wezterm.url.parse, uri)
      if ok and parsed then
        path = safe_field(parsed, 'file_path') or safe_field(parsed, 'path') or uri
      else
        path = uri:match 'file://[^/]*(/.+)' or uri
      end
    else
      path = uri:match 'file://[^/]*(/.+)' or uri
    end
  end

  return normalize_path(path)
end

local function label_from_path(path)
  local normalized = normalize_path(path)
  local home = normalize_path(HOME)

  if normalized == '' then
    return ''
  end
  if normalized == home then
    return '~'
  end

  return basename(normalized)
end

local function title_path(title)
  if not title or title == '' then
    return ''
  end

  local candidate = title
    :gsub('^[^:]+:', '')
    :gsub('^%s+', '')

  if not candidate:find '[/\\]' then
    return ''
  end

  return normalize_path(candidate)
end

local function pane_title(source)
  if not source then
    return ''
  end

  if type(source.get_title) == 'function' then
    local ok, value = pcall(function()
      return source:get_title()
    end)
    if ok and value then
      return value
    end
  end

  return safe_field(source, 'title') or ''
end

local function foreground_process_name(source)
  if not source then
    return ''
  end

  if type(source.get_foreground_process_name) == 'function' then
    local ok, value = pcall(function()
      return source:get_foreground_process_name()
    end)
    if ok and value then
      return value
    end
  end

  return safe_field(source, 'foreground_process_name') or ''
end

local function source_label(source)
  local cwd = label_from_path(path_from_uri(get_cwd_uri(source)))
  if cwd ~= '' then
    return cwd, 'cwd'
  end

  local title = pane_title(source)
  local title_based = label_from_path(title_path(title))
  if title_based ~= '' then
    return title_based, 'title'
  end

  local process = basename(foreground_process_name(source))
  if process ~= '' then
    return process, 'process'
  end

  if title ~= '' then
    return title, 'raw'
  end

  return 'shell', 'fallback'
end

local function cwd_name(source)
  local label = source_label(source)
  return label
end

local function cycle_pane(pane, step)
  local tab = pane and pane:tab()
  if not tab then
    return
  end

  local panes = tab:panes_with_info()
  if #panes < 2 then
    return
  end

  table.sort(panes, function(a, b)
    return a.index < b.index
  end)

  local active = 1
  for index, info in ipairs(panes) do
    if info.is_active then
      active = index
      break
    end
  end

  local target = ((active - 1 + step) % #panes) + 1
  panes[target].pane:activate()
end

local function rename_workspace_action()
  return act.PromptInputLine {
    description = 'Rename workspace',
    action = wezterm.action_callback(function(window, _, line)
      if not line or line == '' then
        return
      end

      wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
      window:toast_notification('WezTerm', 'Workspace renamed to ' .. line, nil, 2000)
    end),
  }
end

local function show_window_picker(window, pane)
  local mux_window = window:mux_window()
  if not mux_window then
    return
  end

  local choices = {}
  for _, info in ipairs(mux_window:tabs_with_info()) do
    local tab = info.tab
    local title = cwd_name(tab:active_pane())

    table.insert(choices, {
      id = tostring(info.index),
      label = string.format('%d: %s', info.index, title),
    })
  end

  window:perform_action(
    act.InputSelector {
      title = 'tmux windows',
      choices = choices,
      action = wezterm.action_callback(function(win, target_pane, id)
        if id then
          win:perform_action(act.ActivateTab(tonumber(id)), target_pane)
        end
      end),
    },
    pane
  )
end

local function show_help(window, pane)
  local choices = {}
  local next_id = 1

  local function help_key_label(key)
    if key == 'Alt + Arrow keys' then
      if IS_DARWIN then
        return '^B \u{2325}\u{2190}\u{2193}\u{2191}\u{2192}'
      end
      return 'Ctrl+B Alt+\u{2190}\u{2193}\u{2191}\u{2192}'
    end

    if key == 'Arrow keys' then
      if IS_DARWIN then
        return '^B \u{2190}\u{2193}\u{2191}\u{2192}'
      end
      return 'Ctrl+B \u{2190}\u{2193}\u{2191}\u{2192}'
    end

    if IS_DARWIN then
      return '^B ' .. key:upper()
    end

    return 'Ctrl+B ' .. key
  end

  for _, section in ipairs(HELP_SECTIONS) do
    table.insert(choices, {
      id = tostring(next_id),
      label = '[' .. section.title .. ']',
    })
    next_id = next_id + 1

    for _, entry in ipairs(section.entries) do
      table.insert(choices, {
        id = tostring(next_id),
        label = string.format('  %-22s %s', help_key_label(entry.key), entry.description),
      })
      next_id = next_id + 1
    end
  end

  window:perform_action(
    act.InputSelector {
      title = 'WezTerm tmux help',
      choices = choices,
      action = wezterm.action_callback(function() end),
    },
    pane
  )
end

local function push_key(keys, key, mods, action)
  table.insert(keys, {
    key = key,
    mods = mods,
    action = action,
  })
end

local function build_tmux_keys()
  local keys = {}

  push_key(keys, 'b', 'LEADER', act.SendKey { key = 'b', mods = 'CTRL' })
  push_key(keys, 'c', 'LEADER', act.SpawnTab 'CurrentPaneDomain')
  if IS_WINDOWS then
    push_key(keys, 't', 'LEADER', wezterm.action_callback(show_windows_shell_picker))
  end
  push_key(keys, 'n', 'LEADER', act.ActivateTabRelative(1))
  push_key(keys, 'p', 'LEADER', act.ActivateTabRelative(-1))
  push_key(keys, 'l', 'LEADER', act.ActivateLastTab)
  push_key(keys, 'w', 'LEADER', wezterm.action_callback(show_window_picker))
  push_key(keys, '&', 'LEADER', act.CloseCurrentTab { confirm = true })
  push_key(keys, 'phys:7', 'LEADER|SHIFT', act.CloseCurrentTab { confirm = true })
  push_key(keys, 'h', 'LEADER', wezterm.action_callback(show_help))

  push_key(keys, '%', 'LEADER', act.SplitHorizontal { domain = 'CurrentPaneDomain' })
  push_key(keys, '"', 'LEADER', act.SplitVertical { domain = 'CurrentPaneDomain' })
  push_key(keys, 'phys:5', 'LEADER|SHIFT', act.SplitHorizontal { domain = 'CurrentPaneDomain' })
  push_key(keys, 'phys:Quote', 'LEADER|SHIFT', act.SplitVertical { domain = 'CurrentPaneDomain' })
  push_key(keys, 'x', 'LEADER', act.CloseCurrentPane { confirm = true })
  push_key(keys, 'z', 'LEADER', act.TogglePaneZoomState)
  push_key(keys, '!', 'LEADER', wezterm.action_callback(function(_, pane)
    if pane then
      pane:move_to_new_tab()
    end
  end))
  push_key(keys, 'phys:1', 'LEADER|SHIFT', wezterm.action_callback(function(_, pane)
    if pane then
      pane:move_to_new_tab()
    end
  end))
  push_key(keys, 'o', 'LEADER', wezterm.action_callback(function(_, pane)
    cycle_pane(pane, 1)
  end))
  push_key(keys, 'q', 'LEADER', act.PaneSelect { alphabet = '1234567890' })
  push_key(keys, '{', 'LEADER', act.RotatePanes 'CounterClockwise')
  push_key(keys, '}', 'LEADER', act.RotatePanes 'Clockwise')
  push_key(keys, 'phys:LeftBracket', 'LEADER|SHIFT', act.RotatePanes 'CounterClockwise')
  push_key(keys, 'phys:RightBracket', 'LEADER|SHIFT', act.RotatePanes 'Clockwise')
  push_key(keys, '[', 'LEADER', act.ActivateCopyMode)
  push_key(keys, ']', 'LEADER', act.PasteFrom 'Clipboard')

  push_key(keys, 's', 'LEADER', act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' })
  push_key(keys, '$', 'LEADER', rename_workspace_action())
  push_key(keys, '(', 'LEADER', act.SwitchWorkspaceRelative(-1))
  push_key(keys, ')', 'LEADER', act.SwitchWorkspaceRelative(1))
  push_key(keys, 'phys:4', 'LEADER|SHIFT', rename_workspace_action())
  push_key(keys, 'phys:9', 'LEADER|SHIFT', act.SwitchWorkspaceRelative(-1))
  push_key(keys, 'phys:0', 'LEADER|SHIFT', act.SwitchWorkspaceRelative(1))

  for index = 0, 9 do
    push_key(keys, tostring(index), 'LEADER', act.ActivateTab(index))
  end

  local directions = {
    { key = 'phys:LeftArrow', direction = 'Left' },
    { key = 'phys:DownArrow', direction = 'Down' },
    { key = 'phys:UpArrow', direction = 'Up' },
    { key = 'phys:RightArrow', direction = 'Right' },
  }

  for _, item in ipairs(directions) do
    push_key(keys, item.key, 'LEADER', act.ActivatePaneDirection(item.direction))
    push_key(keys, item.key, 'LEADER|ALT', act.AdjustPaneSize { item.direction, 5 })
  end

  return keys
end

local function status_cells(window, pane)
  local date = wezterm.strftime '%Y-%m-%d %H:%M '
  local workspace = window:active_workspace()
  local key_table = window:active_key_table()

  local left = {
    { Foreground = { Color = TOKYO_NIGHT.success } },
    { Text = ' ' .. workspace .. ' ' },
  }

  if window:leader_is_active() then
    table.insert(left, { Foreground = { Color = TOKYO_NIGHT.border } })
    table.insert(left, { Text = '| ' })
    table.insert(left, { Foreground = { Color = TOKYO_NIGHT.warning } })
    table.insert(left, { Text = 'PREFIX ' })
  end

  local right = {
    { Foreground = { Color = TOKYO_NIGHT.muted } },
    { Text = 'prefix+h ' },
    { Foreground = { Color = TOKYO_NIGHT.border } },
    { Text = '| ' },
  }
  if key_table then
    right = {
      { Foreground = { Color = TOKYO_NIGHT.accent_alt } },
      { Text = 'mode ' .. key_table .. ' ' },
      { Foreground = { Color = TOKYO_NIGHT.border } },
      { Text = '| ' },
    }
  end
  local right_tail = {
    { Foreground = { Color = TOKYO_NIGHT.text } },
    { Text = date },
  }
  for _, cell in ipairs(right_tail) do
    table.insert(right, cell)
  end

  return left, right
end

local function tab_title(tab)
  if tab.tab_title and tab.tab_title ~= '' then
    return tab.tab_title
  end
  return cwd_name(tab.active_pane)
end

configure_platform(config)

config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 2000 }
config.disable_default_key_bindings = true
config.key_map_preference = 'Mapped'

-- Hangul glyphs usually need a slightly larger fallback scale to sit well next to Latin monospace fonts.
config.font = wezterm.font_with_fallback(build_terminal_fonts())
config.font_size = 11.0
config.line_height = 1.02
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 800
config.use_ime = true

config.color_scheme = 'Tokyo Night'
config.window_background_opacity = 0.95
if IS_DARWIN then
  config.macos_window_background_blur = 40
end
config.window_decorations = 'RESIZE'
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.7 }
config.scrollback_lines = 10000
config.hyperlink_rules = wezterm.default_hyperlink_rules()

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = false
config.tab_and_split_indices_are_zero_based = true
config.tab_max_width = 40
config.status_update_interval = 1000

config.window_frame = {
  font = wezterm.font_with_fallback(build_window_frame_fonts()),
  font_size = 11.0,
  active_titlebar_bg = TOKYO_NIGHT.bg,
  inactive_titlebar_bg = TOKYO_NIGHT.bg,
}

config.colors = {
  tab_bar = {
    background = TOKYO_NIGHT.bg,
    active_tab = {
      bg_color = TOKYO_NIGHT.accent,
      fg_color = TOKYO_NIGHT.bg,
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = TOKYO_NIGHT.surface_alt,
      fg_color = TOKYO_NIGHT.muted,
    },
    inactive_tab_hover = {
      bg_color = TOKYO_NIGHT.border,
      fg_color = TOKYO_NIGHT.text,
    },
  },
}

config.mouse_bindings = build_mouse_bindings()

config.keys = build_tmux_keys()

wezterm.on('update-status', function(window, pane)
  local left, right = status_cells(window, pane)
  window:set_left_status(wezterm.format(left))
  window:set_right_status(wezterm.format(right))

  local tab = pane and pane:tab()
  local title = cwd_name(pane)
  if tab and title ~= '' and tab:get_title() ~= title then
    tab:set_title(title)
  end
end)

wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
  local background = TOKYO_NIGHT.surface_alt
  local foreground = TOKYO_NIGHT.muted

  if tab.is_active then
    background = TOKYO_NIGHT.accent
    foreground = TOKYO_NIGHT.bg
  elseif hover then
    background = TOKYO_NIGHT.border
    foreground = TOKYO_NIGHT.text
  end

  local title = wezterm.truncate_right(tab_title(tab), math.max(1, max_width - 2))

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = ' ' .. title .. ' ' },
  }
end)

return config
