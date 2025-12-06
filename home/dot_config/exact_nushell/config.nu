source ~/.local/share/atuin/init.nu

$env.config = (
  $env.config | upsert keybindings (
    $env.config.keybindings
    | append {
      name: atuin
      modifier: control
      keycode: char_r
      mode: [emacs, vi_normal, vi_insert]
      event: { send: executehostcommand cmd: (_atuin_search_cmd) }
    }
  )
)
