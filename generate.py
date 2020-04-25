import pandas as pd
import stipple
import subprocess
from concorde.tsp import TSPSolver
import time
def read_tour(filename):
    tour = open(filename).read().split()[1:]
    tour = list(map(int, tour))
    if tour[-1] == 0: tour.pop()
    return tour

def read_tsp(filename):
	with open(filename + '.tsp','r') as poo: 
		counter = 0 
		citiesX = [] 
		citiesY = [] 
		line = poo.readlines() 
		for x in line: 
			#print(counter, x.split())
			if counter <= 5: 
			    counter += 1 
			    continue 
			elif x.split()[0] == 'EOF':
				break
			else: 
			    counter += 1 
			    citiesX.append(x.split()[1]) 
			    citiesY.append(x.split()[2]) 
	cities = pd.DataFrame([citiesX,citiesY]).T 
	cities.columns = ['X',"Y"]
	return cities

def drawTSP(filename,cities,tour):
	print('generating TSP art')
	with open(filename+'_TSP.eps','w+') as f:
		f.write('%%!PS-Adobe-3.0 EPSF-3.0\n')
		f.write('%%%%BoundingBox: 0 0 680 470\n')
		f.write('0 setlinecap\n')
		f.write('0 setlinejoin\n')
		f.write('.10 setlinewidth\n')
		f.write(f'{cities.X[tour[0]]} {cities.Y[tour[0]]} newpath moveto\n')
		for tour_i in range(1,len(tour)):
			f.write(f'{cities.X[tour_i]} {cities.Y[tour_i]} lineto\n')
		#f.write('closepath\n')
		f.write('stroke\n')
		f.write('showpage')

def py_drawTSP(filename,cities,tour):
    print('generating TSP art')
    dat = cities.T[tour_data[0]]
    with open(filename+'_TSP.eps','w+') as f:
        f.write('%%!PS-Adobe-3.0 EPSF-3.0\n')
        f.write('%%%%BoundingBox: 0 0 680 470\n')
        f.write('0 setlinecap\n')
        f.write('0 setlinejoin\n')
        f.write('.10 setlinewidth\n')
        f.write(f'{dat[0].X} {cities.T[tour_data[0]][0].Y} newpath moveto\n')
        for col in dat.columns[1:]:
            f.write(f'{dat[col].X} {dat[col].Y} lineto\n')
        #f.write('closepath\n')
        f.write('stroke\n')
        f.write('showpage')

		#f.write('EOF\n')

if __name__ == '__main__':
	picture = 'EL.pgm'
	path_to_concorde = '~/concorde/LINKERN/linkern'
	filename = picture.split('.')[0]
	stipple.py_stipple(picture)
	python = True
	if python == False:
		print('running lin-kern heuristic')
		subprocess.check_call("%s -s 42 -S linkern.tour -R 10000000 -t 120 %s > linkern.log" % (path_to_concorde, filename+'.tsp'),   shell=True)
		out_file = open('linkern.csv', "w")
		sub = subprocess.call(["sed"," -Ene ","'s/([0-9]+) Steps.*Best: ([0-9]+).*/1,2/p'" ,"linkern.log"], stdout=out_file )
		#subprocess.call("sed -Ene 's/([0-9]+) Steps.*Best: ([0-9]+).*/1,2/p' linkern.log >linkern.csv")
		cities = read_tsp(filename)
		tour = read_tour('linkern.tour')
		drawTSP(filename,cities,tour)	
	else:
		cities = read_tsp(filename)
		solver = TSPSolver.from_data(cities.X,cities.Y,norm='EUC_2D')
		t = time.time()
		tour_data = solver.solve(time_bound = 60.0, verbose = True, random_seed=42)
		print(time.time() - t)
		py_drawTSP(filename,cities,tour_data)
