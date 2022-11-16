# mpirun -n 2 python3 primes_mpi_block.py 4

import sys
from mpi4py import MPI
import time
import random

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

comm.barrier()
start=MPI.Wtime()

def nb_primes(n):
    result = 0
    for i in range(1,n+1):
        if n%i == 0:
            result += 1
    return result


upper_bound = int(sys.argv[1])

current_max = 0
#print(((upper_bound//size)*rank+1),((upper_bound//size)*(rank+1)))

for val in range(((upper_bound//size)*rank+1),((upper_bound//size)*(rank+1))+1):    
    #print(val)
    tmp = nb_primes(val)
    current_max = max(current_max, tmp)
#print("local max", rank)
#print(rank,(upper_bound//size+1)*rank+1,(upper_bound//size+1)*(rank+1),current_max)
global_max=comm.reduce(current_max, op=MPI.MAX,root=0)

end = MPI.Wtime()
if rank==0:
    print(global_max,end-start )



