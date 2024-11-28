# Pawn

## Techniques

- Stack buffer overflow (ret2func, ret2sc)
- Heap overflow
- Format string (leak, write)

Chaque technique aura au moins 1 exemple pratique, voir dans `exemples/`

## Format strings

### Forme générique

```c
printf(buf); // Utilisation directe de l'entrée utilisateur
```

### Vulnérabilité

#### Lecture arbitraire (leak)

Permet de lire la mémoire avec des spécificateurs comme %x, %p ou %s

`%x %x %x`: Leak les 3 premieres valeurs de la stack
`%8$x`: Leak la 8eme valeur de la stack

__Mémo__:

- `%x` : Affiche une valeur brute en hexadécimal.

- `%s` : Traite la valeur comme une chaîne de caractères (peut provoquer un segfault si l'adresse pointée est invalide).

- `%p` : Affiche un pointeur (équivalent à %#x).

- `%n` : Écrit le nombre de caractères affichés jusqu'ici à l'adresse fournie (utile pour l'écriture en mémoire).

- `%d` : Affiche une valeur entière en base 10.

- `%ld` : Affiche une valeur entière longue


#### Ecriture arbitraire (write)

Permet d'écrire en mémoire une valeur controllée, le format est :

<adresse>%<valeur>c%<position_sur_la_stack>$n

Par exemple pour ecrire la valeur 0x12345678 à l'adresse 0x05557ff8, et que le buffer est en 1ere position sur la stack : 

```py
payload = b"\xf8\x7f\x55\x05%305419892c%6$n"
#0x12345678 vaut 305419896 donc 305419896-4 = 305419892
```