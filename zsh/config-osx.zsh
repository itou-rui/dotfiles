if command -v exa &> /dev/null; then
  alias ll="exa -l -g --icons"
  alias lla="ll -a"
fi

# Fzf
set -g FZF_PREVIEW_FILE_CMD "bat --style=numbers --color=always --line-range :500"
set -g FZF_LEGACY_KEYBINDINGS 0