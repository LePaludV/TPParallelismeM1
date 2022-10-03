Pour tester :
Quand on va lancer le programme final il faudra préciser en paramètre un fichier.
Ce fichier correspond au vecteur dont on veut faire la somme.
Le premier élément de ce fichier (La 1er ligne) correspond au nombre d'élément qu'il y a dans le vecteur:
n -> 2^n éléments.
Les autres éléments sont donc ceux qu'on va additionner.

Pour créer ce fichier vecteur.txt

Il faut d'abord compiler le generevec.c

    gcc generevec.c

ce qui crée un fichier a.out

On va ensuite l’exécuter:

    ./a.out a b vecteur.txt 

Avec a le nombre d'éléments 2^a et b la valeur max que peut prendre un élément.
On a donc un fichier vecteur.txt un fichier avec 2^a nombres compris entre 0 et b.

Pour compiler le fichier principal il faut faire 
    nvcc vecsum.cu 

Ce qui donne un fichier "a.out" (remplace l'ancien fichier a.out existant)

pour l'executer on fait ensuite:
    ./a.out vecteur.txt

