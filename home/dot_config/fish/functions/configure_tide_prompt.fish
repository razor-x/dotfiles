function configure_tide_prompt \
    --description 'Set and persist tide prompt config'

    tide configure \
      --auto \
      --style=Lean \
      --prompt_colors='16 colors' \
      --show_time=No \
      --lean_prompt_height='Two lines' \
      --prompt_connection=Disconnected \
      --prompt_spacing=Sparse \
      --icons='Many icons' \
      --transient=No
end
