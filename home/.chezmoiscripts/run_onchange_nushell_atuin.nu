#!/usr/bin/env nu

if (which atuin | is-not-empty) {
  $env.ATUIN_NOBIND = true

  let atuin_path = $"($env.HOME)/.local/share/atuin"
  mkdir $atuin_path

  atuin init nu | save --force $"($atuin_path)/init.nu"
} else {
  print 'Cannot install atuin Nushell shell integration: atuin not found.'
  exit 1
}
