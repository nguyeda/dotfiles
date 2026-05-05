# Neovim (AstroNvim) Cheat Sheet

Leader key is **Space** (`<leader>` = `␣`). Local leader is **,**.
Press `<leader>` and wait — **which-key** shows all menus.

## File navigation

| Keys | Action |
|---|---|
| `<leader>e` | Toggle Neo-tree (file side panel) |
| `<leader>o` | Focus Neo-tree if open, else toggle |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fF` | Find files (include hidden) |
| `<leader>fw` | Live grep across project |
| `<leader>fW` | Live grep (include hidden) |
| `<leader>fb` | Find open buffers |
| `<leader>fo` | Find recently opened files |
| `<leader>fh` | Find help tags |
| `<leader>fc` | Find word under cursor |
| `<leader>f/` | Find in current buffer |

### Inside Neo-tree

| Keys | Action |
|---|---|
| `<CR>` / `o` | Open file / expand directory |
| `a` | Add file (`name/` for directory) |
| `d` | Delete |
| `r` | Rename |
| `y` / `x` / `p` | Copy / Cut / Paste |
| `c` | Copy (with prompt) |
| `m` | Move |
| `H` | Toggle hidden files |
| `R` | Refresh |
| `?` | Show all neo-tree keybinds |
| `q` | Close neo-tree |
| `s` / `S` | Open in vsplit / hsplit |
| `t` | Open in new tab |

## Buffers / Windows / Tabs

| Keys | Action |
|---|---|
| `]b` / `[b` | Next / previous buffer |
| `<leader>c` | Close buffer |
| `<leader>C` | Force close buffer |
| `<leader>bd` | Close buffer (pick from tabline) |
| `<C-h/j/k/l>` | Move to window left/down/up/right |
| `<leader>\|` | Vertical split |
| `<leader>-` | Horizontal split |
| `<leader>w` | Save |
| `<leader>q` | Quit |
| `<leader>n` | New buffer |

## LSP (when language server is attached)

| Keys | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gI` | Go to implementation |
| `gr` | Find references |
| `gy` | Go to type definition |
| `K` | Hover docs |
| `<leader>la` | Code action |
| `<leader>lr` | Rename symbol |
| `<leader>lf` | Format file |
| `<leader>ld` | Hover diagnostics |
| `<leader>lG` | Workspace symbols |
| `[d` / `]d` | Previous / next diagnostic |

## Git (Gitsigns)

| Keys | Action |
|---|---|
| `]g` / `[g` | Next / previous hunk |
| `<leader>gl` | Blame line |
| `<leader>gp` | Preview hunk |
| `<leader>gh` | Reset hunk |
| `<leader>gd` | Diff against HEAD |
| `<leader>gb` | Branches (Telescope) |
| `<leader>gc` | Commits (Telescope) |
| `<leader>gt` | Status (Telescope) |

## Plugin / tooling managers

| Command | Purpose |
|---|---|
| `:Lazy` | Plugin manager UI |
| `:Lazy update` | Update all plugins |
| `:Lazy sync` | Install + clean + update |
| `:Mason` | LSP / formatter / linter installer |
| `:checkhealth` | Run all health checks |
| `:TSUpdate` | Update treesitter parsers |

## Editing essentials (vim-native, worth remembering)

| Keys | Action |
|---|---|
| `ciw` / `daw` | Change / delete inner word / a word |
| `ci"` / `ci(` / `ci{` | Change inside quotes/parens/braces |
| `gcc` | Toggle line comment |
| `gc` (visual) | Toggle comment on selection |
| `>>` / `<<` | Indent / dedent line |
| `==` | Auto-indent line |
| `*` / `#` | Search word under cursor forward / back |
| `n` / `N` | Next / previous match |
| `:%s/old/new/g` | Replace all in file |

## Surround (nvim-surround)

| Keys | Action |
|---|---|
| `ys{motion}{char}` | Surround motion with char (e.g. `ysiw"`) |
| `ds{char}` | Delete surrounding char |
| `cs{old}{new}` | Change surrounding (e.g. `cs"'`) |
| `S{char}` (visual) | Surround selection |

## Flash (jump motion)

| Keys | Action |
|---|---|
| `s` | Jump to any location (then type chars) |
| `S` | Jump to treesitter node |

## Quick reference

- **Open file tree**: `<leader>e`
- **Open file**: `<leader>ff`, type, `<CR>`
- **Search project**: `<leader>fw`, type, `<CR>`
- **Save**: `<leader>w`
- **Quit**: `<leader>q`
- **First-time setup / catch-up**: `:Lazy update` then `:TSUpdate` then `:Mason`
- **Lost?**: press `<leader>` and wait, or `:WhichKey`
