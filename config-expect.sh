#!/usr/bin/expect -f
set timeout 10

spawn ./po-util.sh

expect -exact "Branch: "
send -- "latest\n"
expect -exact "Baud Rate: "
send -- "po\n"

interact
