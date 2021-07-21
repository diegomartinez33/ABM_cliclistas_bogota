import os
import sys
import numpy as np
import geopandas as gpd
from geopy import distance
from shapely.geometry import Polygon

shp1 = gpd.read_file(os.path.join('.', 'MVI2020','MVI2020.shp'))
shp2 = gpd.read_file(os.path.join('.', 'ZONAS','ZAT.shp'))

for col in shp1.columns:
	print(col)

print("\n\n")

for col in shp2.columns:
	print(col)