LEFT_CAP=$'\ue0b6'    
RIGHT_CAP=$'\ue0b4'   
CHEVRON=$'\ue0b0'
ACTIVE=$'\uF460'

PROMPT=$'%F{0}%K{default}$LEFT_CAP%k%F{white}%K{0} %n %F{$rbfg2}%K{#87CEFA}$CHEVRON%F{black}%K{#87CEFA} \uEAF7 %~ %F{#87CEFA}%K{default}$RIGHT_CAP%k%f$ACTIVE '

ZSH_THEME_GIT_PROMPT_PREFIX="%F{#D18616}%K{default}$LEFT_CAP%k%F{black}%K{#D18616} \uf418 " # branch icon
ZSH_THEME_GIT_PROMPT_SUFFIX=" %F{#D18616}%K{default}$RIGHT_CAP%k%f"                         # close orange bg
ZSH_THEME_GIT_PROMPT_CLEAN="%b"                                                             # wrap branch
ZSH_THEME_GIT_PROMPT_DIRTY="%b \uf069"                                                      # * if dirty

RPROMPT='$(git_prompt_info)%k%f'