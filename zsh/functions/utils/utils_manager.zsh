#!/usr/bin/env zsh

## Terminal UI
source "${0:A:h}/ui/checklist.zsh"
source "${0:A:h}/ui/confirm.zsh"
source "${0:A:h}/ui/countdown.zsh"
source "${0:A:h}/ui/header.zsh"
source "${0:A:h}/ui/help_box.zsh"
source "${0:A:h}/ui/input.zsh"
source "${0:A:h}/ui/messages.zsh"
source "${0:A:h}/ui/notification.zsh"
source "${0:A:h}/ui/operation_result.zsh"
source "${0:A:h}/ui/pause.zsh"
source "${0:A:h}/ui/progress.zsh"
source "${0:A:h}/ui/select.zsh"
source "${0:A:h}/ui/separator.zsh"
source "${0:A:h}/ui/table.zsh"

## Keychain Operations
source "${0:A:h}/keychain_operations/get_keychains.zsh"
source "${0:A:h}/keychain_operations/unlock_keychains.zsh"
