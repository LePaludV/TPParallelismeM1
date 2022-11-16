from mpi4py import MPI
import sys
import random
import math
import numpy as np
import matplotlib.image as mpimg
import matplotlib.pyplot as plt 
import matplotlib.cm as cm

M = 255
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
# First method for stretching contrast
def f_one(x,n):
	if x==0:
		return 0
	return int(M**(1-n) * (x**n))

# Second method for stretching contrast
def f_two(x,n):
	if x==0:
		return 0
	return int((M**((n-1)/n)) * (x**(1/n)))

# Converts an image to grayscale
def rgb2gray(rgb):
    return np.dot(rgb[...,:3], [0.299, 0.587, 0.114])

# splits a vector "x" in "size" part. In case it does not divide well, the last one receives one less than others
def split(x, size):
	n = math.ceil(len(x) / size)
	return [x[n*i:n*(i+1)] for i in range(size-1)]+[x[n*(size-1):len(x)]]

# unsplits a list x composed of n lists of t elements
def unsplit(x):
	y = []
	n = len(x)
	t = len(x[0])
	for i in range(n):
		for j in range(len(x[i])):
			y.append(x[i][j])
	return y, n, t

# Loads an image on disk named "image.png" and convert it to greyscale, and shows it
def readImage():
	img = mpimg.imread('image.png')
	#print(img.shape)
	plt.imshow(img)
	plt.show()
	grey = rgb2gray(img)
	plt.imshow(grey, cmap = cm.Greys_r)
	pixels, nblines, nbcolumns = unsplit(grey)
	for i in range(0, len(pixels)):
		pixels[i] = int(pixels[i]*255)
	return pixels, nblines, nbcolumns

# Saves the image in "image-grey2-stretched.png" and shows it
def saveImage(newP, nblines, nbcolumns):
	newi = split(newP, nblines)
	newimg = np.zeros((nblines, nbcolumns))
	for rownum in range(nblines):
		for colnum in range(nbcolumns):
			newimg[rownum][colnum] = newi[rownum][colnum]
	plt.imshow(newimg, cmap = cm.Greys_r)
	plt.show()
	mpimg.imsave('image-grey2-stretched.png', newimg, cmap = cm.Greys_r )



# load the image
if rank==0:
	print("Starting stretching...")
	pixels, nblines, nbcolumns = readImage()
	pixels=split(pixels,size)
else:
	pixels=None
#On divise les données "pixels"
local_pixel=comm.scatter(pixels,root=0)

# compute min and max of pixels
local_pix_min = min(local_pixel)
local_pix_max = max(local_pixel)

pix_min=comm.allreduce(local_pix_min,op=MPI.MIN)
pix_max=comm.allreduce(local_pix_max,op=MPI.MAX)

# compute alpha, the parameter for f_* functions
alpha = 1+(pix_max - pix_min) / M

# stretch contrast for all pixels. f_one and f_two are the two different methods

	


for i in range(0,len(local_pixel)):
	if rank%2==0:
		local_pixel[i] = f_one(local_pixel[i], alpha)
	else:
		local_pixel[i] = f_two(local_pixel[i], alpha)

pixels=comm.reduce(local_pixel,op=MPI.SUM,root=0)







# save the image
if rank==0:
	print(len(pixels))
	saveImage(pixels, nblines, nbcolumns)

	print("Stretching done...")


