# StippleSolver

# Setup A (Pure Python) :
0. Make a venv for this repo (recommended). Python 3.5+ works best:
```python3 -m venv TSP  ```
1. activate the venv and use pip to install the following:
```pip3 install numpy pandas matplotlib Pillow cython ```

2. You'll need the concorde TSP solver -- one of the most powerful TSP solvers around, and to get in it python, you'll have to do the following:
  a. clone the python wrapper library 
  ```
  git clone https://github.com/jvkersch/pyconcorde
  cd pyconcorde
  ```
  b. run pip install  (dont forget the period). This may take a minute. 
  ```
  pip3 install -e .
  ```
  c. verify installation. open up the python interpreter and type:
  ```from concorde.tsp import TSPSolver ```
  And make sure it doesn't fail.
  
3. Build the cython project :
```python3 setup.py build_ext --inplace  ```
# Setup B (Cython and C):

0. Make a venv for this repo (recommended). Python 3.5+ works best:
```python3 -m venv TSP  ```
1. activate the venv and use pip to install the following:
```pip3 install numpy pandas matplotlib Pillow cython ```

2. You'll need the concorde TSP solver -- one of the most powerful TSP solvers around, and to get in it python, you'll have to do the following:
  a. Install it from source. http://www.math.uwaterloo.ca/tsp/concorde/downloads/downloads.html . Follow the installation instructions. 
  ```
  git clone https://github.com/jvkersch/pyconcorde
  cd pyconcorde
  ```
  b. If you did not install it in the ~/ directory, change the path_to_concorde variable in the generate.py file, and set python = False in generate.py. 
  
3. Build the cython project :
```python3 setup.py build_ext --inplace  ```
# main goals of this project:
1. Using Cython to create TSP art, guided by Dr.Robert Bosch. 
-- Implementing Lloyds algorithm  (Done) 
-- creating an .eps file and .cyc file for Concorde TSP solver.(Done) 
-- generate TSP art.  (Done) 

2. Generate en masse a large dataset of TSP-art.  (In progress)

3. Train a DCGAN (Deep Convolution Generative Adversarial Network) to create TSP art with a generative method. (In progress)


# To build project:
``` python3 setup.py build_ext --inplace ```

# Example Stippling Usage:
``` python3 generate.py poo.pgm ```

