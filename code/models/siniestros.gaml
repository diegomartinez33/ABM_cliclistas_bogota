/**
* Name: siniestros
* Based on the internal empty template. 
* Author: Diego Martinez y Andrés Useche
* Tags: 
*/

model siniestros

/* Insert your model definition here */

global{
	file shapefile_mvi<-file("../includes/model_input/MVI2020/MVI2020_siniestros2.shp");
	file shapefile_zat<-file("../includes/model_input/ZONAS/zat_bog_filtrado.shp");
	matrix od_zats<-matrix(file("../includes/model_input/matriz_od.csv"));
	matrix od_origen<-matrix(file("../includes/model_input/dist_zat_origen.csv"));
	
	int n_agentes<- 10000;
	geometry shape <- envelope(shapefile_zat);
	float step <- 1#h; //24 #h;
	date starting_date <- date("2021-08-06 05:00:00");
    int min_work_start <- 5;
    int max_work_start <- 7;
    int min_work_end <- 16; 
    int max_work_end <- 19; 
    float min_speed <- 1.0 #km / #h; // TODO: investigar velocidad de bicicleta reportada
    float max_speed <- 5.0 #km / #h; 
    graph the_graph;
    graph the_graph_with_stress;
    int total_siniestros<-0;
    int total_flujo<-0;
    float variacion_estres<-0.0001;
    float variacion_segmento<-0.0001;
    float ruido_blanco<-0.000005;
	init{
		/*Inicialización de las ZATs, los segmentos y la malla*/
		//create segmento from: shapefile_mvi with: [indice_estres::read('indice_estres'), prob_siniestro::read('prob_siniestro')]{}
		
		//do pause;
		
		create segmento from: shapefile_mvi with: [ prob_siniestro::float(read('Probabilidad'))]{
			indice_estres<-prob_siniestro;
			//write prob_siniestro;
			prob_siniestro<-(prob_siniestro+rnd(ruido_blanco));
		}
		
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
		    objective <- "resting";
		    //Asignando la probabilidad de riesgo inicial
		    float aleatorio <-rnd(1.0);
		    if(aleatorio<=0.39){
		    	prob_riesgo<- rnd(0.6,0.8);
		    }else if(aleatorio>0.39 and aleatorio<=0.8){
		    	prob_riesgo<- rnd(0.4,0.6);
		    }else{
		    	prob_riesgo<- rnd(0.3,0.5);
		    }
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
		    //write "Agente:"+name+", zat_origen:"+zat_origen.nombre+", zat destino:"+zat_destino.nombre;
		    //write ", hora de inicio:"+start_work+", hora de fin:"+end_work;
		}
		write "Termino inicializada de los agentes";
		write starting_date;
	}

	reflex actualizar_malla{
		//write time;
		map<segmento,float> pesos_segmentos_estres<-segmento as_map(each::(each.indice_estres)); //Calculando los pesos para cada segmento con base en el índice de seguridad
		the_graph_with_stress <- as_edge_graph(segmento) with_weights pesos_segmentos_estres;	//Creando la red con pesos
	}
	
	reflex detener_simulacion when: cycle>8760{ //Método para detener la simulación
		do pause;
	} 
	
	reflex save_result{
		/* 
		list<segmento> segmentos<- segmento;
		loop i over: segmentos{
			ask i{
				total_siniestros <- total_siniestros + num_siniestros; //Siniestros totales por ciclo
				total_flujo<-total_flujo + flujo_total; //Flujo de ciclistas por ciclo
			}
		}
		* */
		//write "Total de siniestros"+total_siniestros;
		total_siniestros<-total_siniestros+segmento sum_of each.num_siniestros;
		
	    save ("cycle: "+ cycle +
	    	"; siniestros_generados:"+ segmento sum_of each.num_siniestros
		) 
	      to: "prueba.txt" type: "text" rewrite: (cycle = 0) ? true : false;
	    
	    
	    list<float> siniestros<- segmento collect each.num_siniestros;
	    save ("cycle: "+ cycle +
	    	"; siniestros_generados:"+ siniestros
		) 
	      to: "segmentos.txt" type: "text" rewrite: (cycle = 0) ? true : false;
	}
	
}

/*Definición de la clase persona y sus propiedades*/
species persona skills: [moving]{
	float prob_riesgo max: 1.0;
	string tipo_ruta;
	rgb color<- #green;
	point origen <- nil ;
	zat zat_origen;
	zat zat_destino;
    point destino <- nil ;
    int start_work;
    int end_work;
    string objective ; 
    point the_target <- nil ;

    
    // reflex para indicar el momento de ir a trabajar segun la hora
    reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
    	//write "Hora de trabajar al objetivo:"+the_target;
	    objective <- "working" ;
	    the_target <- any_location_in (zat_destino);
    }
    
    // reflex para indicar el momento de volver a casa segun la hora    
    reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
    	//write "Hora de volver al objetivo:"+the_target;
	    objective <- "resting" ;
	    the_target <- origen; 
    } 
    
    // Movimiento de la persona segun el nivel de riesgo
    reflex move when: the_target != nil {
    	graph selected_graph; //variable que define el tipo de grafo o ruta a usar segun el rieso asociado a la persona
    	
    	//aleatorizando el proceso de eleeción de ruta
    	if(rnd(1.0)>prob_riesgo){
    		tipo_ruta<-"Rapida";
    	}else{
    		tipo_ruta<-"Segura";
    	}
    	
    	//Asignando ruta y grafo a partir de la ruta elegida                     
    	if (tipo_ruta="Rapida"){
    		selected_graph <- the_graph;
    		//write "aca";
    	}
    	else {
    		selected_graph <- the_graph_with_stress;
    		//write "aca2";
    	}
    	path path_followed <- goto(target: the_target, on:selected_graph, return_path: true);
    	list<geometry> segments <- path_followed.segments;
    	float aux_rnd_siniestro;
    	
    	loop line over: segments {
    		//write line;
    		aux_rnd_siniestro <- rnd(0.25);
	        ask segmento(path_followed agent_from_geometry line) {
	        	// Se cambia el nivel de estres del segmento si ocurre un siniestro
	        	flujo_total<-flujo_total+1; 
	        	//write "Prob aleatoria:"+aux_rnd_siniestro+", prob segmento:"+prob_siniestro;
	        	if (aux_rnd_siniestro<=prob_siniestro){ 
		        	indice_estres<-indice_estres+variacion_segmento;
		        	num_siniestros<-num_siniestros+1; //aumenta en 1 el No de siniestros
		        	write "sucedio un siniestro";
		        	
		        	myself.prob_riesgo<-myself.prob_riesgo-variacion_estres;
	        	}else{
	        		indice_estres<-indice_estres-variacion_segmento;
	        		myself.prob_riesgo<-myself.prob_riesgo+variacion_estres;
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
    
	aspect base {
	draw circle(80) color: color border: #green; /*Dibujar la figura de los agentes*/
    }
}

/*Definición de la clase segmento y sus propiedades*/
species segmento{
	rgb color<- #lightgray;
	float prob_siniestro max: 1.0; //Probabilidad de que suceda un siniestro
	float indice_estres max: 1.0; //Índice sobre el que se calcula los pesos de la red
	//int colorValue <- int(255*(indice_estres)) update: int(255*(indice_estres));
    //rgb color <- rgb(min([255, colorValue]),0,max ([0, 255 - colorValue]))  update: rgb(min([255, colorValue]),0,max ([0, 255 - colorValue])) ;
	int num_siniestros<-0;
	int flujo_total<-0;
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
    parameter "Latest hour to start work" var: max_work_start category: "People" min: 5 max: 10;
    parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
    parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
    parameter "minimal speed" var: min_speed category: "People" min: 0.1 #km/#h ;
    parameter "maximal speed" var: max_speed category: "People" max: 10 #km/#h;
    parameter "variacion al estres" var: variacion_estres category: "People" min:0.0  max: 0.025;
    parameter "variacion al segmento" var: variacion_segmento category: "People" min:0.0  max: 0.025;
	output {
		/*
	    display malla {
	    	species zat aspect: base;
	        species segmento aspect: base ;
	        species persona aspect:base;
	    }
	    *  */
	    display siniestros_chart {
	    	chart "siniestros totales" type: series{
	    		data "total_siniestros" value: total_siniestros color: #blue;
	    	}
	    }
	}
}

experiment bache type: batch repeat: 5 keep_seed: false until: (cycle=8760){
	
	reflex save_result{
		list<segmento> segmentos<- segmento;
		loop i over: segmentos{
			ask i{
				total_siniestros <- total_siniestros + num_siniestros; //Siniestros totales por ciclo
				total_flujo<-total_flujo + flujo_total; //Flujo de ciclistas por ciclo
			}
		}
		write "Total de siniestros"+total_siniestros;
		
	    save ("cycle: "+ cycle +
	    	"; siniestros_generados:"+ total_siniestros+"; flujo_generado:"+total_flujo
		) 
	      to: "bache1_"+variacion_estres+"_"+variacion_segmento+"_"+ruido_blanco+".txt" type: "text" rewrite: (cycle = 0) ? true : false;
	}
	
}
