#!/usr/bin/expect -f
set timeout 10

spawn ./po-util.sh config

expect -exact "Branch: "
send -- "release/stable\n"
expect -exact "Baud Rate: "
send -- "po\n"

interact
