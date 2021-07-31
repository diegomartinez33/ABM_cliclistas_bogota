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
	file shapefile_zat<-file("../includes/model_input/ZONAS/zat_bog_filtrado.shp");
	matrix od_zats<-matrix(file("../includes/model_input/matriz_od.csv"));
	matrix od_origen<-matrix(file("../includes/model_input/dist_zat_origen.csv"));
	
	int n_agentes<- 1000;
	geometry shape <- envelope(shapefile_zat);
	//float step <- 1 #mn;
	//date starting_date <- date("2021-07-21-06-00-00");
    int min_work_start <- 6;
    int max_work_start <- 7;
    int min_work_end <- 16; 
    int max_work_end <- 20; 
    float min_speed <- 1.0 #km / #h;
    float max_speed <- 5.0 #km / #h; 
    graph the_graph;
	init{
		/*Inicialización de las ZATs, los segmentos y la malla*/
		create segmento from:shapefile_mvi;
		map<segmento,float> pesos_segmentos_seguridad<-segmento as_map(each::(each.indice_seguridad)); //Calculando los pesos para cada segmento con base en el índice de seguridad
		map<segmento,float> pesos_segmentos_siniestros<-segmento as_map(each::(each.prob_siniestro));
		the_graph <- as_edge_graph(segmento) with_weights pesos_segmentos_seguridad;	//Creando la red con pesos
		create zat from:shapefile_zat with: [nombre::string(read("ZAT"))];
			
		/*Inicialización de los agentes*/
		create persona number: n_agentes{
			speed <- rnd(min_speed, max_speed);
		    start_work <- rnd (min_work_start, max_work_start);
		    end_work <- rnd(min_work_end, max_work_end);
		    riesgo_indiv<-rnd(1.0);
		    //Asignando tipo de selección de ruta
		    if(prob_riesgo>0.5){
		    	tipo_ruta<-"Rapida";
		    }else{
		    	tipo_ruta<-"Segura";
		    }
		    /*Asignando ZAT de origen*/
		    float prob_origen<-rnd(1.0);
		    loop i from: 0 to: od_origen.rows-1{
		    	if i = 0{
		    		if prob_origen<=float(od_origen[3,i]){
		    			list<zat> lista_zats<-zat where (each.nombre=string(od_origen[0,i]));
		    			origen <- any_location_in (one_of(lista_zats)) ;
		    			zat_origen<-one_of(lista_zats);
		    			write zat_origen.nombre;
		    		}
		    	}else{
		    		if prob_origen>float(od_origen[3,i-1]) and prob_origen<=float(od_origen[3,i]) {
		    			list<zat> lista_zats<-zat where (each.nombre=string(od_origen[0,i]));
		    			origen <- any_location_in (one_of(lista_zats)) ;
		    			zat_origen<-one_of(lista_zats);
		    			write zat_origen.nombre;
		    		}
		    	}
		    }
		    
		    /*Asignando destino basado en ZAT de origen*/
		    float prob_destino<-rnd(1.0);
		    loop i from: 0 to: od_zats.rows-1{
		    	if zat_origen.nombre=string(od_zats[1,i]){
		    		write "Origen:"+zat_origen.nombre+", destino:"+od_zats[1,i];
		    		if i = 0{
		    			write "Probabilidad acum:"+float(od_zats[6,i]);
			    		if prob_destino<=float(od_zats[6,i]){
			    			list<zat> lista_zats<-zat where (each.nombre=string(od_zats[1,i]));
			    			destino <- any_location_in (one_of(lista_zats)) ;
			    			zat_destino<-one_of(lista_zats);
			    			write zat_destino.nombre;
		    		}
			    	}else{
			    		write "Probabilidad acum:"+float(od_zats[6,i]);
			    		if prob_destino>float(od_zats[6,i-1]) and prob_destino<=float(od_zats[6,i]) {
			    			list<zat> lista_zats<-zat where (each.nombre=string(od_zats[1,i]));
			    			destino <- any_location_in (one_of(lista_zats)) ;
			    			zat_destino<-one_of(lista_zats);
			    			write zat_destino.nombre;
			    		}
			    	}
		    	}	    		    	
		    }
		    location <- origen;
		}
	}

	reflex actualizar_malla{
		map<segmento,float> pesos_segmentos_seguridad<-segmento as_map(each::(each.indice_seguridad)); //Calculando los pesos para cada segmento con base en el índice de seguridad
		the_graph <- as_edge_graph(segmento) with_weights pesos_segmentos_seguridad;	//Creando la red con pesos
	}
	
}

/*Definición de la clase persona y sus propiedades*/
species persona skills: [moving]{
	float prob_riesgo<-rnd(1.0) max: 1.0;
	string tipo_ruta;
	rgb color<- #green;
	point origen <- nil ;
	zat zat_origen;
	zat zat_destino;
    point destino <- nil ;
    int start_work ;
    int end_work  ;
    string objective ; 
    point the_target <- nil ;
    float riesgo_indiv;
        
    reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
	    objective <- "working" ;
	    the_target <- any_location_in (zat_destino);
    }
        
    reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
	    objective <- "resting" ;
	    the_target <- origen; 
    } 
    /* 
    reflex move when: the_target != nil {
    	path path_followed <- goto(target: the_target, on:the_graph, return_path: true);
    	list<geometry> segments <- path_followed.segments;	
    	loop line over: segments {
	        ask segmento(path_followed agent_from_geometry line) { 
	        	indice_seguridad<-indice_seguridad+0.01	;
	        }
	    }
	    if the_target = location {
	        the_target <- nil ;
	    }
    }
    
    */
    
    reflex move when: the_target != nil {
	    do goto target: the_target on: the_graph ; 
	    if the_target = location {
	        the_target <- nil ;
	    }
    }
    /* 
    reflex actualizar_destino{
		float prob_destino<-rnd(1.0);
	    loop i from: 0 to: od_zats.rows-1{
	    	if zat_origen.nombre=string(od_zats[1,i]){
	    		if i = 0{
		    		if prob_destino<=float(od_zats[6,i]){
		    			list<zat> lista_zats<-zat where (each.nombre=string(od_zats[1,i]));
		    			destino <- any_location_in (one_of(lista_zats)) ;
		    			zat_destino<-one_of(lista_zats);
			    	}else{
			    		if prob_destino>float(od_zats[6,i-1]) and prob_destino<=float(od_zats[6,i]) {
			    			list<zat> lista_zats<-zat where (each.nombre=string(od_zats[1,i]));
			    			destino <- any_location_in (one_of(lista_zats)) ;
			    			zat_destino<-one_of(lista_zats);
			    		}
			    	}
	    		}		    		    	
	    	}
    	} 
    }  
    */
	aspect base {
	draw circle(20) color: color border: #green; /*Dibujar la figura de los agentes*/
    }
}

/*Definición de la clase segmento y sus propiedades*/
species segmento{
	rgb color<- #lightgray;
	float prob_siniestro<- rnd(1.0) max: 1.0; //Probabilidad de que suceda un siniestro
	float indice_seguridad <- rnd(1.0) max: 1.0; //Índice sobre el que se calcula los pesos de la red
	aspect base {
    draw shape color: color ; /*Dibujar la figura de los segmentos*/
    }
}

species zat{
	rgb color<- #white;
	string nombre;
	aspect base {
	draw shape color: color border: #red;
	}
}

experiment prueba1 type: gui {
	parameter "Shapefile de la MVI" var: shapefile_mvi category: "GIS";
	parameter "Shapefile de las ZAT" var: shapefile_zat category: "GIS";
	parameter "Número de agentes" var: n_agentes category: "People" ;
	output {
	    display malla {
	    	species zat aspect: base;
	        species segmento aspect: base ;
	        species persona aspect:base;
	    }
	}
}
