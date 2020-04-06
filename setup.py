import setuptools
from distutils.core import setup
from Cython.Build import cythonize
import numpy
import PIL
setup(
	name="TSP ART",
    version="0.0.1",
    author="Tumas Rackaitis",
    author_email="trackait@oberlin.edu",
    description="Solving TSP with Art",
	packages=setuptools.find_packages(),
	ext_modules = cythonize(
		[
		'stipple.pyx'
		]
		,        
	compiler_directives={'language_level': "3"}),
	include_dirs=[numpy.get_include()],
	install_requires=['numpy','PIL'] 
	)
