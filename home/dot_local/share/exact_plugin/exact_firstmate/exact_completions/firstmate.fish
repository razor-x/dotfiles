complete --command firstmate --no-files

complete \
    --command firstmate \
    --keep-order \
    --condition '__fish_use_subcommand
        or __fish_seen_subcommand_from launch station spyglass aheadfull fullstop sail scuttle' \
    --arguments '(__fish_complete_directories)' \
    --description Directory

complete \
    --command firstmate \
    --condition 'not __fish_seen_subcommand_from station' \
    --long-option vessel \
    --exclusive \
    --arguments '(__firstmate_vessels)' \
    --description 'Select vessel (default: flagship)'

complete \
    --command firstmate \
    --condition '__fish_seen_subcommand_from sail' \
    --long-option to \
    --require-parameter \
    --description 'Destination harbor'

complete \
    --command firstmate \
    --condition '__fish_seen_subcommand_from sail' \
    --long-option from \
    --require-parameter \
    --description 'Source harbor'

complete \
    --command firstmate \
    --condition '__fish_seen_subcommand_from sail' \
    --long-option cancel \
    --description 'Cancel an unfinished sail and keep the vessel at its source'

complete \
    --command firstmate \
    --short-option h \
    --long-option help \
    --description 'Show usage'

complete \
    --command firstmate \
    --keep-order \
    --condition __fish_use_subcommand \
    --arguments spyglass \
    --description 'Attach to the vessel tmux server read-only'

# Fish displays later keep-order groups first, ahead of directory candidates.
complete \
    --command firstmate \
    --keep-order \
    --condition __fish_use_subcommand \
    --arguments aheadfull \
    --description 'Resume after fullstop and ask the captain to bring everything back up'

complete \
    --command firstmate \
    --keep-order \
    --condition __fish_use_subcommand \
    --arguments fullstop \
    --description 'Stop local vessel processes without sailing or deleting work'

complete \
    --command firstmate \
    --keep-order \
    --condition __fish_use_subcommand \
    --arguments scuttle \
    --description 'Confirm permanent deletion of the selected local vessel'

complete \
    --command firstmate \
    --keep-order \
    --condition __fish_use_subcommand \
    --arguments sail \
    --description 'Sail the selected vessel'

complete \
    --command firstmate \
    --keep-order \
    --condition __fish_use_subcommand \
    --arguments station \
    --description 'Jump to a local work station'

complete \
    --command firstmate \
    --keep-order \
    --condition __fish_use_subcommand \
    --arguments launch \
    --description 'Start or resume the captain (default)'
