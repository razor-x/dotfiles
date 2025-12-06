#!/usr/bin/env nu

$env.ATUIN_NOBIND = true

let atuin_path = $"($env.HOME)/.local/share/atuin"
mkdir $atuin_path
atuin init nu | save $"($atuin_path)/init.nu"
