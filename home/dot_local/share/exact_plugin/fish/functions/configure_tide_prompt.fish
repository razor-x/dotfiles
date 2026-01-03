function configure_tide_prompt \
    --description 'Set and persist tide prompt config'

    # Configure _tide_item_term.
    set --universal tide_term_color 'FFD1DC'
    set --universal tide_term_bg_color 'normal'

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

    set --universal tide_left_prompt_items \
        os term pwd git newline character
end
