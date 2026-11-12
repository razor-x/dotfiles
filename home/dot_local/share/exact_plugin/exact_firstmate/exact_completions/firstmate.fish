complete -c firstmate -f
complete -c firstmate -n __fish_use_subcommand -a '(__fish_complete_directories)' -d Anchor
complete -c firstmate -l vessel -x -a '(__firstmate_vessels)' -d 'Select vessel (default: flagship)'
complete -c firstmate -l sail-to -x -d 'Send the selected vessel to a harbor, then exit'
complete -c firstmate -l scuttle -d 'Confirm permanent deletion of the selected local vessel'
complete -c firstmate -s h -l help -d 'Show launcher usage'
