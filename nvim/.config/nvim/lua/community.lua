-- AstroCommunity plugin packs.
-- Each pack bundles treesitter parser + LSP + formatter for that language.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- Language packs covering the requested filetypes
  { import = "astrocommunity.pack.typescript" }, -- TS + JS
  { import = "astrocommunity.pack.html-css" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.markdown" },

  -- Colorscheme
  { import = "astrocommunity.colorscheme.catppuccin" },
}
