/**
* Name: siniestros
* Based on the internal empty template. 
* Author: Diego Martinez y Andrés Useche
* Tags: 
*/


model siniestros

/* Insert your model definition here */

global{
	file shapefile_mvi<-file("C:/Users/USER/Dropbox (Uniandes)/Safer_Complex_Systems_Ciclorutas/Analysis/Mallas 2019_2020/MVI2020/MVI2020.shp");
	file shapefile_zat<-file("C:/Users/USER/Dropbox (Uniandes)/Safer_Complex_Systems_Ciclorutas/Analysis/Mallas 2019_2020/ZONAS/ZAT.shp");
	int n_agentes<- 1000;
	geometry shape <- envelope(shapefile_zat);
	float step <- 10 #mn;
	init{
		/*Inicialización de los segmentos */
		create segmento from:shapefile_mvi;
		
		/*Inicialización de los agentes*/
		list<segmento> lista_segmentos<-segmento;
		create persona number: n_agentes{
			location <- any_location_in (one_of (lista_segmentos));
		}
	}
	
}

/*Definición de la clase persona y sus propiedades*/
species persona{
	rgb color<- #orange;
	aspect base {
	draw circle(2) color: color border: #black; /*Dibujar la figura de los agentes*/
    }
}

/*Definición de la clase segmento y sus propiedades*/
species segmento{
	rgb color<- #gray;
	aspect base {
    draw shape color: color ; /*Dibujar la figura de los segmentos*/
    }
}

experiment prueba1 type: gui {
	parameter "Shapefile de la MVI" var: shapefile_mvi category: "GIS";
	parameter "Shapefile de las ZAT" var: shapefile_zat category: "GIS";
	parameter "Número de agentes" var: n_agentes category: "People" ;
	output {
	    display malla type: opengl {
	        species segmento aspect: base ;
	        species persona aspect:base;
	    }
	}
}