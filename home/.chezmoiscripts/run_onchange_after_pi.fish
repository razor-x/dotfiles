#!/usr/bin/env fish

if type --query pi

    pi install npm:pi-mcp-adapter@2.15.0
else
    echo 'Cannot install Pi packages: pi not installed.'
    return 1
end
