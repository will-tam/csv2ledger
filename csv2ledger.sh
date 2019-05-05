#!/bin/sh

die()
{
    echo "$1"
    exit 1
}

[ $# -eq 0 ] && die "With which file i should work ?"

echo "prout"
