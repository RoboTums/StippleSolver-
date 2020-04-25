import matplotlib as mpl
import matplotlib.pyplot as plt
import pandas as pd
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

		#f.write('EOF\n')

cities = read_tsp('poo')
tour = read_tour('linkern.tour')
drawTSP('poo',cities,tour)
plt.figure(figsize=(20, 20))
plt.plot(cities.X[tour], cities.Y[tour], alpha=0.7)


