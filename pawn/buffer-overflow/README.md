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

