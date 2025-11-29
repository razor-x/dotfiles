function arch_package_optional_deps \
    --description "Show all missing optional dependencies."

    pacman -Qi | awk '
      /^Name/ {pkg = $3}
      /^Optional Deps/ {in_opt = 1; found = 0; next}
      in_opt {
        if (/^[A-Z]/) {in_opt = 0}
        else if (!/None/ && !/installed/) {
          if (!found) {print "\n" pkg ":"; found = 1}
          print "  " $0
        }
      }
    '
end
