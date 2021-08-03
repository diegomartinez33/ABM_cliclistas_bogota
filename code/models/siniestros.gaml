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
	
	int n_agentes<- 10;
	geometry shape <- envelope(shapefile_zat);
	float step <- 10 #mn;
	date starting_date <- date("2021-08-03-00-00-00");
    int min_work_start <- 5;
    int max_work_start <- 7;
    int min_work_end <- 17; 
    int max_work_end <- 19; 
    float min_speed <- 1.0 #km / #h; // TODO: investigar velocidad de bicicleta reportada
    float max_speed <- 5.0 #km / #h; 
    graph the_graph;
    graph the_graph_with_stress;
	init{
		/*Inicialización de las ZATs, los segmentos y la malla*/
		//create segmento from: shapefile_mvi with: [indice_estres::read('indice_estres'), prob_siniestro::read('prob_siniestro')]{}
		create segmento from:shapefile_mvi{
			num_siniestros <- 0;
		}
		//create segmento from: shapefile_mvi with: [indice_estres::read('indice_estres'), prob_siniestro::read('prob_siniestro')];
		
		//Calculando los pesos para cada segmento con base en el índice de seguridad o indice de estres
		map<segmento,float> pesos_segmentos_estres<-segmento as_map(each::(each.indice_estres));
		//Asociando cada segmento con su porcentaje de siniestro
		//map<segmento,float> prob_segmentos_siniestros<-segmento as_map(each::(each.prob_siniestro));
		
		//grafos de calles con pesos por segmento segun indice de estres
		the_graph_with_stress <- as_edge_graph(segmento) with_weights pesos_segmentos_estres;	
		//Creando la red sin pesos
		the_graph <- as_edge_graph(segmento);
		
		//Creacion de las zat segun su id de No de ZAT en el shapefile 
		create zat from:shapefile_zat with: [nombre::string(read("ZAT"))];
			
		/*Inicialización de los agentes*/
		create persona number: n_agentes{
			speed <- rnd(min_speed, max_speed); //velocidad de movimiento
		    start_work <- rnd (min_work_start, max_work_start); //hora de ir a trabajar
		    end_work <- rnd(min_work_end, max_work_end); //hora de salir de trabajar y volver a casa
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
		    			//write zat_origen.nombre;
		    		}
		    	}else{
		    		if prob_origen>float(od_origen[3,i-1]) and prob_origen<=float(od_origen[3,i]) {
		    			list<zat> lista_zats<-zat where (each.nombre=string(od_origen[0,i]));
		    			origen <- any_location_in (one_of(lista_zats)) ;
		    			zat_origen<-one_of(lista_zats);
		    			//write zat_origen.nombre;
		    		}
		    	}
		    }
		    
		    /*Asignando destino basado en ZAT de origen*/
		    float prob_destino<-rnd(1.0);
		    loop i from: 0 to: od_zats.rows-1{
		    	if zat_origen.nombre=string(od_zats[1,i]){
		    		//write "Origen:"+zat_origen.nombre+", destino:"+od_zats[1,i];
		    		if i = 0{
		    			//write "Probabilidad acum:"+float(od_zats[6,i]);
			    		if prob_destino<=float(od_zats[6,i]){
			    			list<zat> lista_zats<-zat where (each.nombre=string(od_zats[1,i]));
			    			destino <- any_location_in (one_of(lista_zats)) ;
			    			zat_destino<-one_of(lista_zats);
			    			//write zat_destino.nombre;
		    		}
			    	}else{
			    		//write "Probabilidad acum:"+float(od_zats[6,i]);
			    		if prob_destino>float(od_zats[6,i-1]) and prob_destino<=float(od_zats[6,i]) {
			    			list<zat> lista_zats<-zat where (each.nombre=string(od_zats[1,i]));
			    			destino <- any_location_in (one_of(lista_zats)) ;
			    			zat_destino<-one_of(lista_zats);
			    			//write zat_destino.nombre;
			    		}
			    	}
		    	}	    		    	
		    }
		    location <- origen;
		}
	}

	reflex actualizar_malla{
		map<segmento,float> pesos_segmentos_estres<-segmento as_map(each::(each.indice_estres)); //Calculando los pesos para cada segmento con base en el índice de seguridad
		the_graph_with_stress <- as_edge_graph(segmento) with_weights pesos_segmentos_estres;	//Creando la red con pesos
		write current_date;
	}
	
	/*
	//The simulation stops at 24:00
	reflex stopSimulation when: cycle = 1441{
		write "Total simulation time: " + (machine_time - simulationStartTime)/1000/60 + " min";
		do pause;
	}
	* 
	*/
	
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
    
    // reflex para indicar el momento de ir a trabajar segun la hora
    reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
	    objective <- "working" ;
	    the_target <- any_location_in (zat_destino);
    }
    
    // reflex para indicar el momento de volver a casa segun la hora    
    reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
	    objective <- "resting" ;
	    the_target <- origen; 
    } 
    
    // Movimiento de la persona segun el nivel de riesgo
    reflex move when: the_target != nil {
    	graph selected_graph; //variable que define el tipo de grafo o ruta a usar segun el rieso 
    	                      //asociado a la persona
    	                      
    	if (tipo_ruta="Rapida"){
    		selected_graph <- the_graph;
    	}
    	else {
    		selected_graph <- the_graph_with_stress;
    	}
	    	path path_followed <- goto(target: the_target, on:selected_graph, return_path: true);
	    	list<geometry> segments <- path_followed.segments;
	    	float aux_rnd_siniestro;
	    	
	    	loop line over: segments {
	    		aux_rnd_siniestro <- rnd(1.0);
		        ask segmento(path_followed agent_from_geometry line) {
		        	// Se cambia el nivel de estres del segmento si ocurre un siniestro 
		        	if (aux_rnd_siniestro>prob_siniestro){ 
			        	indice_estres<-indice_estres+0.01;
			        	num_siniestros<-num_siniestros+1; //aumenta en 1 el No de siniestros
			        	
			        	//Disminuye en 0.1 el nivel de riesgo de la persona
			        	// NO SE SI ES LA MEJOR FORMA DE DISMINUIR EL RIESGO 
			        	// TODO: ¡¡¡¡¡¡¡¡¡¡¡¡¡REVISAR!!!!!!!!!!!!!!!!!!!!
			        	//
			        	myself.prob_riesgo<-myself.prob_riesgo-0.1;
		        	}
		        }
		    }
	    if the_target = location {
	        the_target <- nil ;
	    }
    }
    
    // reflex para actualizar el tipo de ruta a tomar según el nivel de riesgo asociado a la persona
    reflex actualizar_tipo_ruta{
    	if(prob_riesgo>0.5){
	    	tipo_ruta<-"Rapida";
	    }else{
	    	tipo_ruta<-"Segura";
	    }
    }
    
    
    /*
    reflex move when: the_target != nil {
	    do goto target: the_target on: the_graph ; 
	    if the_target = location {
	        the_target <- nil ;
	    }
    } 
    */
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
	draw circle(80) color: color border: #green; /*Dibujar la figura de los agentes*/
    }
}

/*Definición de la clase segmento y sus propiedades*/
species segmento{
	//rgb color<- #lightgray;
	float prob_siniestro<- rnd(1.0) max: 1.0; //Probabilidad de que suceda un siniestro
	float indice_estres <- rnd(1.0) max: 1.0; //Índice sobre el que se calcula los pesos de la red
	int colorValue <- int(255*(indice_estres)) update: int(255*(indice_estres));
    rgb color <- rgb(min([255, colorValue]),0,max ([0, 255 - colorValue]))  update: rgb(min([255, colorValue]),0,max ([0, 255 - colorValue])) ;
	int num_siniestros;
	aspect base {
    draw shape color: color  /*Dibujar la figura de los segmentos*/
    width:1+indice_estres*0.05;
    }
}

species zat{
	rgb color<- #white;
	string nombre;
	aspect base {
	draw shape color: color border: #gray;
	}
}

experiment prueba1 type: gui {
	parameter "Shapefile de la MVI" var: shapefile_mvi category: "GIS";
	parameter "Shapefile de las ZAT" var: shapefile_zat category: "GIS";
	parameter "Número de agentes" var: n_agentes category: "People" ;
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
    parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
    parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
    parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
    parameter "minimal speed" var: min_speed category: "People" min: 0.1 #km/#h ;
    parameter "maximal speed" var: max_speed category: "People" max: 10 #km/#h;
	output {
	    display malla {
	    	species zat aspect: base;
	        species segmento aspect: base ;
	        species persona aspect:base;
	    }
	}
}
