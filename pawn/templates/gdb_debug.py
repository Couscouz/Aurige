#!/usr/bin/env python3
from pwn import *

URL = "xxx.y"
PORT = 4321

bin_name = "crackme"

context.update(arch='amd64')
# context.log_level = 'debug'

if args.GDB:
    context.terminal = ["terminator", "-x"]
    p = gdb.debug(f"./{bin_name}", """
    source /home/user/.gdbinit-gef.py
    break *(main+XX)
    continue
    """)
elif args.LOCAL:
    p = process(f"./{bin_name}")
else:
    p = remote(URL, PORT)

p.settimeout(TIMEOUT)




p.interactive()