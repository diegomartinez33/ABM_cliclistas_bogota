/**
* Name: siniestros
* Based on the internal empty template. 
* Author: Diego Martinez y Andrés Useche
* Tags: 
*/


model siniestros

/* Insert your model definition here */

global{
	file shapefile_mvi<-file("../includes/model_input/MVI2020/MVI2020.shp");
	file shapefile_zat<-file("../includes/model_input/ZONAS/ZAT.shp");
	int n_agentes<- 10;
	geometry shape <- envelope(shapefile_zat);
	float step <- 10 #mn;
	date starting_date <- date("2021-07-21-00-00-00");
    int min_work_start <- 6;
    int max_work_start <- 8;
    int min_work_end <- 16; 
    int max_work_end <- 20; 
    float min_speed <- 20.0 #km / #h;
    float max_speed <- 50.0 #km / #h; 
    graph the_graph;
	init{
		/*Inicialización de los segmentos */
		create segmento from:shapefile_mvi;
		the_graph <- as_edge_graph(segmento);
		
		create zat from:shapefile_zat;
		
		/*Inicialización de los agentes*/
		list<segmento> lista_segmentos<-segmento;
		list<zat> lista_zats<-zat;
		create persona number: n_agentes{
			speed <- rnd(min_speed, max_speed);
		    start_work <- rnd (min_work_start, max_work_start);
		    end_work <- rnd(min_work_end, max_work_end);
		    living_place <- any_location_in (one_of (lista_zats)) ;
		    working_place <- any_location_in (one_of (lista_zats));
		    objective <- "resting";
			location <- any_location_in (one_of (lista_segmentos));
		}
	}
	
}

/*Definición de la clase persona y sus propiedades*/
species persona skills: [moving]{
	rgb color<- #orange;
	point living_place <- nil ;
    point working_place <- nil ;
    int start_work ;
    int end_work  ;
    string objective ; 
    point the_target <- nil ;
        
    reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
    objective <- "working" ;
    the_target <- any_location_in (working_place);
    }
        
    reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
    objective <- "resting" ;
    the_target <- any_location_in (living_place); 
    } 
     
    reflex move when: the_target != nil {
    do goto target: the_target on: the_graph ; 
    if the_target = location {
        the_target <- nil ;
    }
    }
	aspect base {
	draw circle(200) color: color border: #black; /*Dibujar la figura de los agentes*/
    }
}

/*Definición de la clase segmento y sus propiedades*/
species segmento{
	rgb color<- #gray;
	aspect base {
    draw shape color: color ; /*Dibujar la figura de los segmentos*/
    }
}

species zat{
	rgb color<- #lightskyblue;
	aspect base {
	draw shape color: color border: #black;
	}
}

experiment prueba1 type: gui {
	parameter "Shapefile de la MVI" var: shapefile_mvi category: "GIS";
	parameter "Shapefile de las ZAT" var: shapefile_zat category: "GIS";
	parameter "Número de agentes" var: n_agentes category: "People" ;
	output {
	    display malla type: opengl {
	    	species zat aspect: base;
	        species segmento aspect: base ;
	        species persona aspect:base;
	    }
	}
}