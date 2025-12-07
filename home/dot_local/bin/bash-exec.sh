#!/usr/bin/env bash

set -u

{{ template "bash_env" . }}

exec "$@"
