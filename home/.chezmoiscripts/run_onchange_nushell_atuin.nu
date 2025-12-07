#!/usr/bin/env nu

if (which atuin | is-not-empty) {
  $env.ATUIN_NOBIND = true

  let atuin_path = $"($env.HOME)/.local/share/atuin"
  mkdir $atuin_path

  atuin init nu | save $"($atuin_path)/init.nu"
} else {
  echo 'Skipping Nushell atuin init: atuin not found.'
}
