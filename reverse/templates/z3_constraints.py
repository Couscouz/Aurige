#!/usr/bin/python3

from z3 import *
import subprocess

s = Solver()
n1 = BitVec('n1', 32)
n2 = BitVec('n2', 32)
n3 = BitVec('n3', 32)
n4 = BitVec('n4', 32)
n5 = BitVec('n5', 32)
p1 = BitVec('p1', 32)
p2 = BitVec('p2', 32)
p3 = BitVec('p3', 32)

# Les blocs font 2 octets, donc n1-5 peuvent aller jusque 2**16, soit 65536
s.add(n1 >= 0, n1 < 65536)
s.add(n2 >= 0, n2 < 65536)
s.add(n3 >= 0, n3 < 65536)
s.add(n4 >= 0, n4 < 65536)
s.add(n5 >= 0, n5 < 65536)

# Ici on ajoute la formule du checksum, pour forcer n5 à être bon
s.add(n5 == n2 * 0x2 & n1 >> 0x1 ^ n3 ^ n4)

# On définit les paramètres de check3
s.add(p1 == n2 | (n1 << 16))
s.add(p2 == 0xC0DE * n5)
s.add(p3 == n4 | (n3 << 16))

# On applique check3
s.add(p3 == (p2 | ~p1) + (p1 | ~p2) - 2 * ~(p2 | p1) - 2 * (p2 & p1))

# Tant qu'une solution existe, on affiche
while s.check() == sat:
    model = s.model()
    licence = '-'.join([f'{model[n].as_long():0>4X}' for n in [n1, n2, n3, n4, n5]])

    # Test en direct la licence
    out = subprocess.run(f'echo {licence} | ./task', shell=True, capture_output=True).stdout.decode()
    if 'Allez acheter une licence' not in out:
        print(licence)

    # Sert à trouver une nouvelle solution
    s.add(Or(n1 != model[n1], n2 != model[n2], n3 != model[n3], n4 != model[n4]))