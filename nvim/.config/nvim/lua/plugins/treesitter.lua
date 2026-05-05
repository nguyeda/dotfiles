-- Extend treesitter parsers beyond what the language packs already pull in.
-- (xml isn't in any AstroCommunity pack we're using, so add it here.)

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "xml",
    },
  },
}
