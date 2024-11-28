#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

char *gets(char *);

void success() {
    printf("Bravo ! Vous avez réussi à exécuter success() !\n");
}

int main() {
    char buffer[64];

    printf("Votre nom: ");
    gets(buffer);
    return 0;
}