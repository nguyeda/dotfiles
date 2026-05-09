-- AstroCommunity plugin packs.
-- Each pack bundles treesitter parser + LSP + formatter for that language.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- Language packs covering the requested filetypes
  { import = "astrocommunity.pack.typescript" }, -- TS + JS
  { import = "astrocommunity.pack.html-css" },
  -- Python: hand-pick sub-packs to skip black/isort (we use ruff + uv)
  { import = "astrocommunity.pack.python.base" },
  { import = "astrocommunity.pack.python.basedpyright" },
  { import = "astrocommunity.pack.python.ruff" },
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.terraform" },

  -- Formatter shared across web filetypes (JS/TS/CSS/HTML/JSON/YAML/MD)
  { import = "astrocommunity.pack.prettier" },

  -- Colorscheme
  { import = "astrocommunity.colorscheme.catppuccin" },
}
