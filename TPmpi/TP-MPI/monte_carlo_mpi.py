# mpirun -n 2 python3 ./monte_carlo_mpi.py

from mpi4py import MPI
import time
import random

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
inside = 0
nb = 100000
random.seed(0)


if rank==0:
    start_time = time.time()
if(rank<nb%size):
    n=nb//size+1
else:
    n=nb//size

for _ in range(n):
    x = random.random()
    y = random.random()
    if x*x + y*y <= 1:
        inside +=1


global_inside=comm.reduce(inside,op=MPI.SUM,root=0)
print(inside)
if rank==0:
    end_time = time.time()
    print("Pi =", 4 * global_inside/nb, "in ", end_time-start_time, 'seconds')

