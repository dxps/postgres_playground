#!/bin/sh

sudo patronictl -c /etc/patroni/postgresql.yml list --extended --timestamp --watch 5

