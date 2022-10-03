
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <cuda.h>

#define BLOCK_SIZE 1024

/*
Le principe :

On n'a pas assez de threads sur un bloc pour s'occuper de tous les éléments du tableau.
Donc on va "découper" ce grand tableau en plusieurs plus petits.
Chaque "sous-tableau" va faire le calcul de sa somme. On récupère ensuite le résultat de la somme des "sous tableau"
Qu'on place dans un tableau temporaire. Et on calcule ensuite la somme de ce tableau temporaire.

Je mets "sous tableau" entre guillemets car on ne crée pas de sous tableau. cf vidéo du cours qui expliquera mieux que moi.
*/


void reduce(unsigned int *vec,unsigned int*sum, int size);
__device__ void kreduceBlock (unsigned int *d_vec, int size);
__global__ void kreduce2 (unsigned int *d_tmp, int size);
__global__ void kreduce1 (unsigned int *d_in, unsigned int *d_tmp, int size );

int main(int argc, char **argv){
  if (argc < 2){
     printf("Usage: <filename>\n");
     exit(-1);
   }
   int size;
   unsigned int *vec;
   FILE *f = fopen(argv[1],"r");
   fscanf(f,"%d\n",&size);
   size = 1 << size;
   if (size >= (1 << 20)){
     printf("Size (%u) is too large: size is limited to 2^20\n",size);
     exit(-1);
   }
    vec = (unsigned int *) malloc(size * sizeof(unsigned int)); assert(vec);
   for (int i=0; i<size; i++){
     fscanf(f, "%u\n",&(vec[i]));
   }
   unsigned int sum=0;


   reduce(vec,&sum,size);
   printf("sum = %u\n", sum);

  unsigned int sum2 = 0;
  for (int i=0; i<size; i++){
    sum2 += vec[i];
  }
  printf("sum2 = %u\n", sum2);

  fclose(f);
  return 0;
}

void reduce(unsigned int *vec,unsigned int *sum, int size){

  unsigned int *d_vec,*d_tmp;
  int bytes = size*sizeof(unsigned int);
  cudaMalloc((void **)&d_vec, bytes);
  cudaMalloc((void **)&d_tmp, bytes /BLOCK_SIZE +1);
  cudaMemcpy(d_vec,vec,bytes,cudaMemcpyHostToDevice);
  int num_blocks = size / BLOCK_SIZE;
  if (size % BLOCK_SIZE) num_blocks ++;

  kreduce1<<<num_blocks,BLOCK_SIZE>>>(d_vec,d_tmp,size);

  /*Après kreduce1 notre d_tmp est donc remplie des sommes des "sous tableau" de d_vec
  On s'est donc ramené à un tableau d'une taille < 1024 qui peut être traité par un seul block
*/
  kreduce2<<<1,size/BLOCK_SIZE +1>>>(d_tmp,size/BLOCK_SIZE +1);
  

  cudaMemcpy(sum,d_tmp,sizeof(unsigned int),cudaMemcpyDeviceToHost);
  cudaFree(d_vec);cudaFree(d_tmp);
}

__device__ void kreduceBlock (unsigned int *d_vec, int size){
  int id=threadIdx.x;
  for(int i=size/2;i>=1;i>>=1){
    if(id<i && id+i<size){
      d_vec[id]+=d_vec[id+i];}
      __syncthreads();

  }}

  __global__ void kreduce1 (unsigned int *d_vec, unsigned int *d_tmp, int size ){
    int block_id = blockIdx.x;
    int offset = block_id * BLOCK_SIZE;
    int n = BLOCK_SIZE;
    if ( block_id == gridDim.x-1){// dernier bloc
      n = size-block_id*BLOCK_SIZE;
    }
    kreduceBlock(&(d_vec[offset]),n);
    /*On place de résultat obtenu dans le "sous tableau" dans le 
    tableau temporaire a l'indice du block.
    Un thread par block s'occupe de cette action(car une seule action a faire) */
    if (threadIdx.x== 0){
      d_tmp[block_id] = d_vec[offset] ;
    }
  }

    __global__ void kreduce2 (unsigned int *d_tmp, int size){
      int id=threadIdx.x;
      for(int i=size/2;i>=1;i>>=1){
        if(id<i && id+i<size){
          d_tmp[id]+=d_tmp[id+i];}
          __syncthreads();

      }}
