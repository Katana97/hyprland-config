# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi

source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export SDL_JOYSTICK_HIDAPI_PS4_RUMBLE=1
export SDL_JOYSTICK_HIDAPI_PS4=1
alias restore-gruvbox="cd ~/gruvbox-end4-theme && ./install.sh"
alias restore-gruvbox="cd ~/gruvbox-end4-theme && ./install.sh"



# Created by `pipx` on 2026-02-22 12:04:19
export PATH="$PATH:/home/david/.local/bin"

alias fix-shure='sudo rm -rf /var/lib/bluetooth/*/00:0E:DD:73:75:9B/cache && bluetoothctl disconnect 00:0E:DD:73:75:9B && sleep 2 && bluetoothctl connect 00:0E:DD:73:75:9B'
