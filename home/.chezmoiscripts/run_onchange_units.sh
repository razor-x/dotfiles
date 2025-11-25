#!/usr/bin/env bash

set -e
set -u

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent
