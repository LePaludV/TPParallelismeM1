from tkinter import N
from xxlimited import new
from matplotlib import pyplot as plt
import networkx as nx
from mpi4py import MPI
import time
import random
import math


#mpirun -n 2 python3 graph-base_mpi.py 

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

comm.barrier()
start=MPI.Wtime()

def split(x, size):
	n = math.ceil(len(x) / size)
	return [x[n*i:n*(i+1)] for i in range(size-1)]+[x[n*(size-1):len(x)]]

def unsplit(x):
	y = []
	n = len(x)
	t = len(x[0])
	for i in range(n):
		for j in range(len(x[i])):
			y.append(x[i][j])
	return y, n, t


def plot_graph(graph, save=False, display=False):
    g1=graph
    plt.tight_layout()
    nx.draw_networkx(g1, arrows=True)
    if save:
        plt.savefig("graph.png", format="PNG")
    if display:
        plt.show(block=True)


#graph = nx.scale_free_graph(20).reverse()
graph = nx.gnr_graph(10, .01).reverse()
#graph = nx.random_k_out_graph(20, 2, .8).reverse()

global_new_elements = [0] # We start at the root (node = 0)
old_elements = []  # We initialize the already seen nodes

while len(global_new_elements) != 0: # as long as we have new node
    tmp = []
    if rank==0:
        splited_global_elements=split(global_new_elements,size)
    else:
        splited_global_elements=None

    local_elements=comm.scatter(splited_global_elements,root=0)

    for node_src in local_elements: # we take all these nodes
        for node in graph.neighbors(node_src): # we take all their descendents
            if not node in old_elements and not node in global_new_elements and not node in tmp:
                # If the descendent is not already seen, we keep it
                tmp.append(node)
    
    old_elements += global_new_elements # we have looked at all their descendent, so we move them to the seen nodes
    #global_new_elements = tmp   # these are the new node, we will see them on the next iteration
    global_new_elements=comm.allreduce(tmp,op=MPI.SUM) 






comm.barrier()
end = MPI.Wtime()
if rank==0:
    print(len(old_elements) == len(graph))
    plot_graph(graph, save=True, display=False)
    print(end-start )

