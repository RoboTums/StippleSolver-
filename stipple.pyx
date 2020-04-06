"""
	Stipples image provided in by command line.
	Creates an associated postscript file and .cyc file. 
"""

__author__ = 'Tumas Rackaitis'

import numpy as np
from PIL import Image
cimport numpy as np
from cython.parallel import prange
#Loads in image and calls the C stipple function. Adjust hyper parameters in the function call. 

cpdef void py_stipple(str filename):
	
	print('Loading image...')
	try:
		image = np.array(Image.open('./'+filename),np.float)
		stipple(
			image,
			4000,{
			'num_zones': 10,
			'num_outer_iters':10,
			'iter_multiple':1000,
			'exp':1.3,
			'n_rows': image.shape[0],
			'n_cols': image.shape[1],
			}
			)

	except FileNotFoundError:
		print(f'image file {filename} does not exist in this directory. Try again. \n')
	
#Stipples the target image. Takes in an np.float64 array as an image, int: num_dots, and a dictionary of hyper parameters.

cdef void stipple(double[:,:] image, int num_dots, dict hyper_params):  

	#initialize variables.
	cdef int num_zones = hyper_params['num_zones']
	cdef int num_outer_iters = hyper_params['num_outer_iters']
	cdef int iter_multiple = hyper_params['iter_multiple']
	cdef double exp = hyper_params['exp']
	cdef int rows = hyper_params['n_rows']
	cdef int max_zone_size = (40 * num_dots )// (num_zones*num_zones)
	cdef int columns = hyper_params['n_cols']
	cdef np.ndarray[np.int32_t,ndim=2] darkness = np.empty([rows,columns],dtype=np.int32)
	cdef np.ndarray[np.float64_t,ndim=1] row_total = np.empty([rows],dtype=np.float64)
	cdef np.ndarray[np.float64_t,ndim=1] row_cdf = np.empty([rows],dtype=np.float64)
	cdef np.ndarray[np.float64_t,ndim=2] cdf = np.empty([rows,columns],dtype=np.float64)
	cdef np.ndarray[np.int32_t,ndim=2] zone_size = np.zeros([num_zones,num_zones],dtype=np.int32)
	cdef np.ndarray[np.int32_t,ndim=3] dots_in_zone = np.empty([num_zones,num_zones, max_zone_size],dtype=np.int32)

	cdef int r,c,k # iterators through images. r = row, c = col , k = dots
	cdef double brightness_val
	cdef double running_sum_total = 0
	cdef double rando
	cdef bint continue_loop
	cdef int row_z, col_z, ncz, row_z_lo, row_z_hi, col_z_lo, col_z_hi
	#set seed.
	np.random.seed(seed=42)
	
	#	Read in the grayscale values. They measure how bright 
	#	a pixel is on a 0-to-255 (black-to-white) scale. We 
	#	subtract each one from 255 to produce darkness values
	#	measured on a 0-to-255 (white-to-black) scale. We then
	#	adjust the darkness values.
	for r in range(rows):
		for c in range(columns):
			brightness_val = 255 - image[r][c]
			darkness[r][c] = np.int( 255 * np.power( (brightness_val / 255) , exp ))


	#construct cumulative distribution function of darkness values.
	
	#first get the sum across the rows. 
	for r in range(rows):
		row_total[r] = 0.0
		row_total[r] = darkness[r].sum()
		running_sum_total += row_total[r]
		#make a valid row cdf
		row_cdf[r] = row_total[r]/running_sum_total 
	
	running_sum_total = 0.0

	#make the whole row_cdf a cdf across all rows.
	for r in range(rows):
		row_cdf[r] += running_sum_total
		running_sum_total = row_cdf[r]
		for c in range(columns):
			cdf[r][c] = darkness[r][c]/row_total[r]

	for r in range(rows):
		running_sum_total = 0.0
		for c in range(columns):
			cdf[r][c] += running_sum_total
			running_sum_total = cdf[r][c]

	print('CDF constructed.')

	#create initial collection of dots (Dart throwing phase of algorithm)

	for k in range(num_dots):
		rando = np.random.random()
		r = 0
		continue_loop = True
		#find location in our CDF where the next element would be higher than our random value. That's where the dart's thrown. 
		while(continue_loop == True): 
			if rando <= row_cdf[r]:	
				c = 0
				rando = np.random.random()
				while(continue_loop == True):
					if rando <= cdf[r][c]:
						continue_loop = False
					else:
						c += 1
			else:
				r += 1
	#having found the correct r,c index of the dart, we add it to the right zone. 
	row_z = np.int(r/zone_height)
	col_z = np.int(c/zone_width) 


