complete --command firstmate --no-files

complete \
    --command firstmate \
    --condition __fish_use_subcommand \
    --arguments '(__fish_complete_directories)' \
    --description Anchor

complete \
    --command firstmate \
    --long-option vessel \
    --exclusive \
    --arguments '(__firstmate_vessels)' \
    --description 'Select vessel (default: flagship)'

complete \
    --command firstmate \
    --long-option sail-to \
    --exclusive \
    --description 'Send the selected vessel to a harbor, then exit'

complete \
    --command firstmate \
    --condition 'test (count (commandline -opc)) -eq 2' \
    --arguments sail \
    --description 'Sail the selected vessel'

complete \
    --command firstmate \
    --condition 'contains -- sail (commandline -opc)' \
    --long-option cancel \
    --description 'Cancel an unfinished sail and keep the vessel at its source'

complete \
    --command firstmate \
    --long-option scuttle \
    --description 'Confirm permanent deletion of the selected local vessel'

complete \
    --command firstmate \
    --short-option h \
    --long-option help \
    --description 'Show launcher usage'
