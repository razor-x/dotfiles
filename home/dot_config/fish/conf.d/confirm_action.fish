function confirm_action -a message default_action
  if test "$default_action" = 'y'
    set prompt '[Y/n]'
    set default_result 0
  else
    set prompt '[y/N]'
    set default_result 1
  end

  read -P "$message $prompt " -n 1 confirm
  echo

  switch $confirm
    case ''
      return $default_result
    case Y y
      return 0
    case N n
      return 1
  end
end
