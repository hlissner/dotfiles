#!/usr/bin/env zsh
ssh root@nas0.lan "docker exec -u www-data ix-nextcloud-nextcloud-1 occ $@"
