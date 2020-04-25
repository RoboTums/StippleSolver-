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
		feed_dict = {
			'num_zones': 1,
			'num_outer_iters':10,
			'iter_multiple':1000,
			'exp':1.3,
			'n_rows': image.shape[0],
			'n_cols': image.shape[1],
			'LW': 2.0, #line width
			'BW':10.0, #border width
 			'PW': 3.0, #pixel width
			 'filename' : filename.split('.')[0] #split on the dot, then get the actual name. 
			}

		stipple(
			image, 2048,feed_dict
			)

	except FileNotFoundError:
		print(f'image file {filename} does not exist in this directory. Try again. \n')
	
#Stipples the target image. Takes in an np.float64 array as an image, int: num_dots, and a dictionary of hyper parameters.

cdef void stipple(double[:,:] image, int num_dots, dict hyper_params):  

	#initialize variables.
	cdef int num_zones = hyper_params['num_zones']
	cdef int num_outer_iters = hyper_params['num_outer_iters']
	cdef int iter_multiple = hyper_params['iter_multiple']
	cdef int iterations = iter_multiple * num_dots
	cdef double exp = hyper_params['exp']
	cdef int rows = hyper_params['n_rows']
	cdef int max_zone_size = (40 * num_dots )// (num_zones*num_zones)
	cdef int columns = hyper_params['n_cols']
	cdef int zone_height = rows // num_zones
	cdef int zone_width = columns // num_zones
	#postscript definitions
	cdef double LW = hyper_params['LW']
	cdef double BW = hyper_params['BW']
	cdef double PW = hyper_params['PW']
	cdef double PSH = (rows * PW) + (2 * BW) #post script height.
	cdef double PSW = (columns * PW) + (2 * BW) #postscript width

	cdef double x_new
	cdef double y_new

	#arrays
	cdef np.ndarray[np.int32_t,ndim=2] darkness = np.empty([rows,columns],dtype=np.int32)
	cdef np.ndarray[np.float64_t,ndim=1] row_total = np.empty([rows],dtype=np.float64)
	cdef np.ndarray[np.float64_t,ndim=1] row_cdf = np.empty([rows],dtype=np.float64)
	cdef np.ndarray[np.float64_t,ndim=2] cdf = np.empty([rows,columns],dtype=np.float64)
	cdef np.ndarray[np.int32_t,ndim=2] zone_size = np.zeros([num_zones,num_zones],dtype=np.int32)
	cdef np.ndarray[np.int32_t,ndim=3] dots_in_zone = np.empty([num_zones,num_zones, max_zone_size],dtype=np.int32)
	cdef np.ndarray[np.float64_t,ndim=1] x_dots = np.empty([num_dots],dtype=np.float64)
	cdef np.ndarray[np.float64_t,ndim=1] y_dots = np.empty([num_dots],dtype=np.float64)
	cdef np.ndarray[np.float64_t,ndim=1] dots_used = np.empty(num_dots,dtype=np.float64)

	


	
	cdef int r,c,k,oi,i # iterators through images. r = row, c = col , k = dots, oi = outer iterations, i = iterations.
	cdef double brightness_val
	cdef double running_sum_total = 0
	cdef double rando,min_dist
	cdef bint continue_loop
	cdef int row_z, col_z, ncz, row_z_lo, row_z_hi, col_z_lo, col_z_hi ,arg_min, arg_min_row_z, arg_min_col_z,dot

	#add postscript locations of dots. 

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
		row_total[r] = darkness[r].sum() + 0.00000000001 #dealing with all white rows.
		running_sum_total += row_total[r] + 0.00000000001  #make sure its not zero, but really close to it. 

	#make a valid row cdf
	for r in range(rows):

		row_cdf[r] = row_total[r]/running_sum_total 
	
	running_sum_total = 0.0

	#make the whole row_cdf a cdf across all rows.
	for r in range(rows):
		row_cdf[r] += running_sum_total
		running_sum_total = row_cdf[r]
		for c in range(columns):
			cdf[r][c] = darkness[r][c]/row_total[r]

	for r in range(rows):
		running_sum_total = 0.0001
		for c in range(columns):
			cdf[r][c] += running_sum_total
			running_sum_total = cdf[r][c]
			cdf[r][c] = min(1,cdf[r][c])
	print('CDF constructed.')


	#create initial collection of dots (Dart throwing phase of algorithm)
	#print('zh',zone_size)
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
		row_z = np.int(r//zone_height)
		col_z = np.int(c//zone_width) 

		#adjust postscript location of dots. 
		x_dots[k] = c * PW + (PW * np.random.random())
		y_dots[k] = (PW * rows - (r * PW)  ) - (PW * np.random.random())

		#assign location of dot into zone.
		dots_in_zone[row_z][col_z][zone_size[row_z][col_z]] = k

		zone_size[row_z][col_z] = zone_size[row_z][col_z] + 1

		if zone_size[row_z][col_z] >= max_zone_size:
			print(f"Warning: Zone {row_z} x {col_z} contains too many dots. ")
			return
		#end of dart throwing.

	print('end of dart throwing.')
	
	#now we move the darts/cities, the tractor beam part of the algorithm. 
	for oi in range(num_outer_iters):
		

		for k in range(num_dots):
			dots_used[k] = 0
		
		for i in range(iterations):
			if i % 100000 == 0:
				print(f"work on outer iteration {oi} is {np.round( ((100*i)/ iterations) ,2 )} percent complete")
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
							if c + 1 >= columns:
								continue_loop = False
							else:
								c += 1
				else:
					if r + 1 >= rows:
						continue_loop = False
					else:
						r += 1
		#	print(f'gets to postscript location. ')
			#update postscript location
			x_new = c * PW + (PW * np.random.random())
			y_new = ((PW * rows) - (r * PW) ) - (PW * np.random.random()) 	
			#update zones
			row_z = np.int(r//zone_height)
			col_z = np.int(c//zone_width)
			#find zone specific maximums and minimas
			row_z_lo = np.max([0 , row_z - 1]) #floor at 0
			row_z_hi = np.min([num_zones - 1, row_z + 1])
			col_z_lo = np.max([0 , col_z - 1]) #floor at 0
			col_z_hi = np.min([num_zones - 1, col_z + 1])
			arg_min = 0
			min_dist = PW*rows+PW*columns #starts as maximum amount of pixels. 
			#iterate through zone.
			#print(f'zone size:, {row_z_hi} , {col_z_hi}')

			for row_z in range(row_z_lo,row_z_hi,1):
				for col_z in range(col_z_lo,col_z_hi,1):
					#print('is it the k loop?')
					for k in range(zone_size[row_z][col_z]):
						#print(k)
						dot = dots_in_zone[row_z][col_z][k]
						dist = (x_dots[dot] - x_new) * (x_dots[dot] - x_new) - (y_dots[dot] - y_new)*(y_dots[dot] - y_new)
						if dist < min_dist:
							min_dist = dist
							arg_min = dot
							arg_min_row_z = row_z
							arg_min_col_z = col_z
				
			x_dots[arg_min] = (dots_used[arg_min] * x_dots[arg_min] + x_new)/(dots_used[arg_min] + 1.0)
			y_dots[arg_min] = (dots_used[arg_min] * y_dots[arg_min] + y_new)/(dots_used[arg_min] + 1.0)
			dots_used[arg_min] += 1

	
#create TSP file.
	print('creating .tsp file')
	with open(hyper_params['filename'] + ".tsp", "w+") as f:
		f.write('NAME : %s\n' % "Tumas Rackaitis")
		f.write('COMMENT : %s\n' % "Math Art Project")
		f.write('TYPE : TSP\n')
		f.write('DIMENSION : %d\n' % num_dots)
		f.write('EDGE_WEIGHT_TYPE : EUC_2D\n')
		f.write('NODE_COORD_SECTION\n')		
		for k in range(num_dots):
			f.write(f'{k+1} {np.round(x_dots[k],10)} {np.round(y_dots[k], 10)}\n')
		f.write('EOF\n')

	print('generated .tsp file')

	#We create the Postscript file : filename.eps
	print('creating postscript file...')
	with open(hyper_params['filename'] +'.eps','w+') as eps:
		eps.write("%%!PS-Adobe-3.0 EPSF-3.0\n")
		eps.write(f"%%%%BoundingBox: 0 0 {np.int(PSW)} {np.int(PSH)} \n\n")
		eps.write("0 setlinecap\n")
		eps.write("0 setlinejoin\n")
		eps.write(f"{LW} setlinewidth\n\n")
		for k in range(num_dots):
			eps.write(f"{np.round(x_dots[k] + BW , 6)} {np.round(y_dots[k] + BW,6)} {LW} 0 360 arc\n")
			eps.write('fill\n')
		eps.write("showpage\n")
	print('postscript file closed. Stippling Complete. ')
