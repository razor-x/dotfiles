function confirm_action -a message default_action
  if test "$default_action" = "y"
    set prompt "[Y/n]"
  else
    set prompt "[y/N] "
  end

  read -P "$message $prompt " -n 1 confirm

  switch $confirm
    case '' Y y
      return 1
    case N n
      return 0
  end
end
