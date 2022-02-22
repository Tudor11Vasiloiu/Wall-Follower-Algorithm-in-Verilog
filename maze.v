`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:01:11 12/03/2021 
// Design Name: 
// Module Name:    maze 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
// aici am definit starile automatului
`define inceput_labirint 0
`define start 1
`define verificare_deplasare 2
`define deplasare 3
`define verificare_pozitie 4
`define stop 5
`define state_aux 6 // aceasta stare este necesara ca sa obtin informatia de la punctul viitor
// am realizat ca este necesara atunci cand lucram la starea start si mi-am amintit ca informatia
// se afla la urmatorul ciclu de ceas, deci trebuia cumva sa ma deplasez inainte si abia dupa sa
// verific punctul in care ma aflu
module maze(
	input clk,
	input [maze_width - 1:0] starting_col, starting_row, 	// indicii punctului de start
	input maze_in, 			// ofera informa?ii despre punctul de coordonate [row, col]
	output reg[maze_width - 1:0] row, col,	 		// selecteaza un rând si o coloana din labirint
	output reg maze_oe,			// output enable (activeaza citirea din labirint la rândul ?i coloana date) - semnal sincron	
	output reg maze_we, 			// write enable (activeaza scrierea în labirint la rândul ?i coloana date) - semnal sincron
	output reg done);		 	// ie?irea din labirint a fost gasita; semnalul ramane activ 

	parameter maze_width = 6;

//variabile
	reg[maze_width - 1:0] row_aux, col_aux; // in aceste variabile retin pozitia anterioara
	reg[1:0] directii;
	reg[2:0] state, state_next; // starile
// voi urmari peretele drept, iar directiile sunt definite astfel:
`define sus 0
`define jos 1
`define stanga 2
`define dreapta 3

//-----------------------------------------------//
	always@(posedge clk)
	begin
		if(done != 1)
			state <= state_next;
		if(directii == 4)
			directii <= 0;
	end
	
//----------------------------------------------//

	always@(*)
	begin
		state_next = `inceput_labirint; // necesar pentru a putea pleca din prima stare a automatului
		maze_we = 0;
		maze_oe = 0;
		done = 0;
		
		case(state)
		
			`inceput_labirint:
			begin
				row = starting_row;
				col = starting_col; // ma plasez in punctul initial
				directii = `jos; // presupun ca pot pleca in dreapta
				maze_we = 1; // stiu sigur ca ma aflu pe o pozitie marcata cu 0
				
				//retin pozitia curenta
				row_aux = starting_row;
				col_aux = starting_col;
				
				state_next = `start;
			end
			
			`start:
			begin
				case(directii)
					`sus: row = row-1;
					`jos: row = row+1;
					`dreapta: col = col+1;
					`stanga: col = col-1;
					default: ;
				endcase
				maze_oe = 1;
				state_next = `state_aux;
			end
			
			`state_aux:
			begin
				case(maze_in)
					0: // in cazul acesta, am gasit pe unde trebuie sa plec
					begin
						row_aux = row;
						col_aux = col;
						maze_we = 1;
						state_next = `verificare_deplasare;
					end
					
					1: // ma intorc in pozitia anterioara, fiindca am "intrat in perete"
					begin
						directii = directii + 1;
						col = col_aux;
						row = row_aux;
						
						state_next = `start;
					end
					
				endcase
			end
			
			`verificare_deplasare:
			begin
				// aceasta stare e asemanatoare cu state_aux
				// in sensul ca ma deplasez in functie de valoarea din deplasare
				// "dreapta" difera in functie de directia de deplasare
				case(directii)
					`dreapta:
					begin
						row_aux = row; // salvez pozitia
						row = row + 1; // verific daca ma pot deplasa inspre jos
					end
					
					`stanga:
					begin
						row_aux = row;
						row = row - 1; // verific sus
					end
					
					`jos:
					begin
						col_aux = col;
						col = col - 1; // verific stanga
					end
					
					`sus:
					begin
						col_aux = col;
						col = col + 1; // verific dreapta
					end

				endcase
				
				maze_oe = 1;
				state_next = `deplasare;
			end
			
			`deplasare:
			begin
				case(directii) // in functie de rezultatul verificarii deplasarii
				//voi sti in ce directie sa merg
					
					`dreapta:
					begin
						case(maze_in)
						0:
						begin
							row_aux = row;
							col_aux = col;
							directii = `jos; // merg in jos pentru a urmari peretele din dreapta
						end
						
						1: 
						begin
							row = row_aux; // trebuie sa ma intorc pentru ca am perete
							col_aux = col;
							col = col + 1; // merg inspre dreapta
						end
						
						endcase
					end
					
					`stanga:
					begin
						case(maze_in)
							0: // salvez datele si ma deplasez in sus
							begin
								row_aux = row;
								col_aux = col;
								directii = `sus;
							end
							1: // am perete si trebuie sa ma intorc
							begin
								row = row_aux;
								col_aux = col;
								col = col - 1;
							end
						endcase
					end
					
					`jos:
					begin
						case(maze_in)
							0:
							begin
								col_aux = col;
								row_aux = row;
								directii = `stanga;
							end
							
							1:
							begin
								col = col_aux;
								row_aux = row;
								row = row + 1;
							end
						endcase
					end
					
					`sus:
					begin
						case(maze_in)
							0:
							begin
								col_aux = col;
								row_aux = row;
								directii = `dreapta;
							end
							
							1:
							begin
								col = col_aux;
								row_aux = row;
								row = row - 1;
							end
						endcase
					end
				endcase // de la deplasare
				maze_oe = 1;
				state_next = `verificare_pozitie;
			end
			
			`verificare_pozitie: // in aceasta stare verific daca in pozitia in care ma aflu
			// este 0 sau 1 si daca sunt in afara labirintului sau nu
			begin
				case(maze_in)
					0: // am 0 deci verific daca am iesit sau mai am de mers
					begin
						if(col == 0 || row == 0 || col == 63 || row == 63)
						begin // in acest caz sunt undeva pe marginea labirintului deci am iesit
							maze_we = 1;
							state_next = `stop;
						end
						
						else // nu am iesit din labirint deci trebuie sa salvez pozitia curenta si
						// sa verific directia de deplasare pentru a cauta iesirea
						begin
							state_next = `verificare_deplasare;
							maze_we = 1;
							col_aux = col;
							row_aux = row;
						end
					end
					
					1: // in situatia asta, trebuie sa ma intorc in pozitia anterioara si sa ma 
					// asigur ca la pasul urmator nu ma deplasez in acest loc
					begin
						row = row_aux;
						col = col_aux;
						// pentru a fi sigur ca evit sa ajung in acelasi loc, voi schimba
						// directia de deplasare in sens opus, adica din dreapta fac stanga
						// si din sus fac jos si viceversa
						case(directii)
							`sus: directii = `jos;
							`jos: directii = `sus;
							`stanga: directii = `dreapta;
							`dreapta: directii = `stanga;
						endcase
						state_next = `verificare_deplasare;
					end
				endcase
				
				
			end // de la verificare pozitie
			
			`stop: done = 1;
			default: ;
		endcase // de la case mare
	end

endmodule
