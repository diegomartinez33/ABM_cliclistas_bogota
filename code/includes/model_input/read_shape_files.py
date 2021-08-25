import os
import sys
import numpy as np
import geopandas as gpd
import pandas as pd
#from geopy import distance
#from shapely.geometry import Polygon

#shp1 = gpd.read_file(os.path.join('.', 'MVI2020','MVI2020_siniestros2.shp'))
shp2 = gpd.read_file(os.path.join('.', 'ZONAS','zat_bog_filtrado.shp'))
df_zat_origen = pd.read_csv('dist_zat_origen.csv', sep=';')

#for col in shp1.columns:
#	print(col)

#print(shp1["Prbbldd"].max())
#print("\n\n")

for col in shp2.columns:
	print(col)

list_zats=shp2["ZAT"].values
zats_origen=df_zat_origen["zat_origen"].values
lista_origen_not_found = []

for origen in zats_origen:
	occurence = False
	for zat in list_zats:
		if origen == zat:
			occurence = True
			break
	if occurence == False:
		lista_origen_not_found.append(origen)

print(lista_origen_not_found)
zat_missed=shp2[shp2['ZAT'] == 0]
print(zat_missed)

shp2.drop('geometry',axis=1).to_csv('zats.csv')