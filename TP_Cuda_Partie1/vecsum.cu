
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <cuda.h>

//Déclaration des prototypes des fonctions du fichier.
void reduce(unsigned int *vec,unsigned int*sum, int size);
__global__ void kreduce (unsigned int *tab, int size);

/*
L'intérieur du main reprend le code de vecsum.c (la version en code séquentiel)

On va récupérer l'argument qu'on a donné quand on exécute le ficher compilé.
Cet argument correspond au fichier vecteur.txt

On va ensuite le charger dans la mémoire à l'adresse du pointeur vec

*/
int main(int argc, char **argv){
  
  if (argc < 2){
    //Argument non valide
     printf("Usage: <filename>\n");
     exit(-1);
   }
   int size;
   unsigned int *vec;

   //On ouvre le fichier qu'on "place" dans f 
   FILE *f = fopen(argv[1],"r");
  //On récupère sa taille
   fscanf(f,"%d\n",&size);

   size = 1 << size;
   if (size >= (1 << 20)){
     printf("Size (%u) is too large: size is limited to 2^20\n",size);
     exit(-1);
   }
  
  //allocation de l'espace nécessaire au tableau vec
  vec = (unsigned int *) malloc(size * sizeof(unsigned int)); assert(vec);

  //boucle qui lit tous les éléments du fichier et les met dans vec
   for (int i=0; i<size; i++){
     fscanf(f, "%u\n",&(vec[i]));
   }
   unsigned int sum=0;

  /*Appel de la fonction de base avec en paramètre : 
  le vecteur
  l'addresse où doit être stocker la somme
  la taille du vecteur

  On donne l'adresse du sum (en utilisant "&" avant) pour pouvoir modifier sa valeur en s'addressant 
  directement a l'espace mémoire où est stocker sum et non à la variable sum
  */
  reduce(vec,&sum,size);
  printf("sum = %u\n", sum);


  /*
  Code séquentiel basique qui fait la somme du vecteur de façon classique (permet de vérifier)
  unsigned int sum2 = 0;
  for (int i=0; i<size; i++){
    sum2 += vec[i];
  }
  printf("sum2 = %u\n", sum2);
  */
  fclose(f);
  return 0;
}

void reduce(unsigned int *vec,unsigned int *sum, int size){

  unsigned int *d_vec;
  int bytes = size*sizeof(unsigned int);
  //Allocation de l'espace mémoire du gpu pour stocker le tableau vecteur
  cudaMalloc((void **)&d_vec, bytes);
  //Copie des donnec dans le gpu
  cudaMemcpy(d_vec,vec,bytes,cudaMemcpyHostToDevice);

  kreduce<<<1,size>>>(d_vec,size);

  /*Copie du résultat :
  On fait un Memcpy de d_vec : d_vec est un tableau mais comme on met juste d_vec sans indice (d_vec[x])
  alors d_vec vaut le premier élément du tableau => d_vec = d_vec[0] 
  */
  cudaMemcpy(sum,d_vec,sizeof(unsigned int),cudaMemcpyDeviceToHost);
  cudaFree(d_vec);
}

__global__ void kreduce (unsigned int *tab, int size){
  int id=threadIdx.x;
  for(int i=size/2;i>0;i=i/2){
    if(id<i && id+i<size){
      tab[id]+=tab[id+i];}
      __syncthreads();

  }}
