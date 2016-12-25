#!/usr/bin/expect -f
set timeout 10

spawn ./po-util.sh config

expect -exact "Branch: "
send -- "release/v0.6.1-rc.1\n"
expect -exact "Baud Rate: "
send -- "po\n"

interact
