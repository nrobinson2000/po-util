#!/usr/bin/expect
log_user 0
set timeout 10

spawn ./po-util.sh

log_user 0

expect "Branch: "
send "latest\r"

log_user 0

expect "Baud Rate: "
send "po\r"

interact
