PROMPT=$'%F{0}%K{default}\uE0B6%k%F{white}%K{0} %n %F{$rbfg2}%K{#87CEFA}\uE0B0 %F{black}%K{#87CEFA} \uEAF7 %~ %F{#87CEFA}%K{default}\uE0B4%k%f\uF460 '

ZSH_THEME_GIT_PROMPT_PREFIX="%F{black}%K{#D18616} \uf418 " # branch icon
ZSH_THEME_GIT_PROMPT_SUFFIX=" %k%f"                        # close orange bg
ZSH_THEME_GIT_PROMPT_CLEAN="%b"                            # wrap branch
ZSH_THEME_GIT_PROMPT_DIRTY="%b \uf069"                     # * if dirty

# 3) set RPROMPT to wrap $(git_prompt_info) in your half-circle caps
RPROMPT=$'%F{#D18616}%K{default}\uE0B6%k'\
'$(git_prompt_info)'\
$'%F{#D18616}%K{default}\uE0B4%k%f'
