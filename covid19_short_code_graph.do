* ===================================================================================================
* Fecha: 12 Abril 2020
* Objetivo: Graficos y analisis de estadisticas Covid19
* Fuente de datos: Github Johns Hopkins University
*
* Adaptacion de: Chuck Huber, Associate Director of Statistical Outreach, STATA Corp.
*Version de: Tiare Rivera
*
* Variables clave: 
*          - Numero de contagiados.
*		   - Numero de muertes.
*		   - Numero de recuperados.
*		   - Nuevos Casos diarios.
* 
* ===================================================================================================

* setup
capture log close
set more off 

*open log file 
log using graficar_covid19, replace text 

clear all

*Traemos el codigo realizado anteriormente en el archivo Covid19_TRT
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/01-29-2020.csv", encoding(utf-8)

*Traemos cada fecha y hacemos merge, ademas de cambiar unificar nombres de variables
*Tiempo estimado: 5 minutos

local URL = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/"
forvalues month = 1/12 {
    forvalues day = 1/31 {
        local month = string(`month', "%02.0f") 
        local day = string(`day', "%02.0f") 
        local year = "2020"
        local today = "`month'-`day'-`year'"
        local FileName = "`URL'`today'.csv"
        clear
        capture import delimited "`FileName'", encoding(utf-8)
        capture rename province_state provincestate
        capture rename country_region countryregion
        capture rename last_update lastupdate
        capture rename lat latitude
        capture rename long longitude
        generate tempdate = "`today'"
        capture save "`today'", replace
    }
}
clear
forvalues month = 1/12 {
    forvalues day = 1/31 {
        local month = string(`month', "%02.0f") 
        local day = string(`day', "%02.0f") 
        local year = "2020"
        local today = "`month'-`day'-`year'"
        capture append using "`today'"
    }
}

*Formato Europeo
generate datesp =date(tempdate, "MDY")
format datesp %tdDD/NN/CCYY

*Arreglo de Variable China
replace countryregion = "China" if countryregion =="Mainland China"	 

**Colocar paises de interes
**Enfoque Latinoamericano
keep if inlist(countryregion, "Argentina", "Brazil", "Chile", "Colombia", "Ecuador", "Mexico", "Nicaragua","Peru")

*Dejar totales
collapse (sum) confirmed deaths recovered, by(datesp countryregion)

*Dejar pais como valor numerico
encode countryregion, gen(pais)

*Vemos el codigo del pais
label list pais

*Declaramos time series de tipo panel
tsset pais datesp, daily

*Generamos nuevos casos
generate nuevoscasos = D.confirmed	 

*Grabamos esta nueva version 
save covide19_long2, replace

*Variables que queremos dejar
keep datesp pais confirmed deaths recovered nuevoscasos

* reshape los datos de "long" a "wide"
reshape wide confirmed deaths recovered nuevoscasos, i(datesp) j(pais)

*1 Argentina
*2 Brazil
*3 Chile
*4 Colombia
*5 Ecuador
*6 Mexico
*7 Nicaragua
*8 Peru

*Loop para renombrar los confirmados
local vars1 "confirmed1 confirmed2 confirmed3 confirmed4 confirmed5 confirmed6 confirmed7 confirmed8"
local vars2 "Argentina_c Brazil_c Chile_c Colombia_c Ecuador_c Mexico_c Nicaragua_c Peru_c"
local n: word count `vars1'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
rename `v1' `v2'
}

*Loop para poner label a las variables de confirmados
local vars1 `" "Argentina_c" "Brazil_c" "Chile_c" "Colombia_c" "Ecuador_c" "Mexico_c" "Nicaragua_c" "Peru_c" "'
local vars2 `" "Contagios Argentina" "Contagios Brazil" "Contagios Chile" "Contagios Colombia" "Contagios Ecuador" "Contagios Mexico" "Contagios Nicaragua" "Contagios Peru" "'
local n: word count `vars2'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
label var `v1' "`v2'"
}


*Loop para renombrar las muertes
local vars1 "deaths1 deaths2 deaths3 deaths4 deaths5 deaths6 deaths7 deaths8"
local vars2 "Argentina_d Brazil_d Chile_d Colombia_d Ecuador_d Mexico_d Nicaragua_d Peru_d"
local n: word count `vars1'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
rename `v1' `v2'
}

*Loop para poner label a las variables de muertes
local vars1 `" "Argentina_d" "Brazil_d" "Chile_d" "Colombia_d" "Ecuador_d" "Mexico_d" "Nicaragua_d" "Peru_d" "'
local vars2 `" "Muertes en Argentina" "Muertes en Brazil" "Muertes en Chile" "Muertes en Colombia" "Muertes en Ecuador" "Muertes en Mexico" "Muertes en Nicaragua" "Muertes en Peru" "'
local n: word count `vars2'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
label var `v1' "`v2'"
}

*Loop para renombrar los recuperados
local vars1 "recovered1 recovered2 recovered3 recovered4 recovered5 recovered6 recovered7 recovered8"
local vars2 "Argentina_r Brazil_r Chile_r Colombia_r Ecuador_r Mexico_r Nicaragua_r Peru_r"
local n: word count `vars1'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
rename `v1' `v2'
}

*Loop para poner label a las variables de recuperados
local vars1 `" "Argentina_r" "Brazil_r" "Chile_r" "Colombia_r" "Ecuador_r" "Mexico_r" "Nicaragua_r" "Peru_r" "'
local vars2 `" "Recuperados en Argentina" "Recuperados en Brazil" "Recuperados en Chile" "Recuperados en Colombia" "Recuperados en Ecuador" "Recuperados en Mexico" "Recuperados en Nicaragua" "Recuperados en Peru" "'
local n: word count `vars2'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
label var `v1' "`v2'"
}

*Loop para renombrar los nuevos casos
local vars1 "nuevoscasos1 nuevoscasos2 nuevoscasos3 nuevoscasos4 nuevoscasos5 nuevoscasos6 nuevoscasos7 nuevoscasos8"
local vars2 "Argentina_n Brazil_n Chile_n Colombia_n Ecuador_n Mexico_n Nicaragua_n Peru_n"
local n: word count `vars1'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
rename `v1' `v2'
}

*Loop para poner label a los nuevos casos
local vars1 `" "Argentina_n" "Brazil_n" "Chile_n" "Colombia_n" "Ecuador_n" "Mexico_n" "Nicaragua_n" "Peru_n" "'
local vars2 `" "Nuevos Argentina" "Nuevos Brazil" "Nuevos Chile" "Nuevos Colombia" "Nuevos Ecuador" "Nuevos Mexico" "Nuevos Nicaragua" "Nuevos Peru" "'
local n: word count `vars2'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
label var `v1' "`v2'"
}

*************************GRAFICAR************************
*********************************************************	 
* Podemos ver los casos confirmados acumulados a la fecha para estos paises

twoway (line Argentina_c datesp, lwidth(thick))          ///
       (line Brazil_c datesp, lwidth(thick))             ///
	   (line Chile_c datesp, lwidth(thick))              ///
       (line Colombia_c datesp, lwidth(thick))           ///
       (line Ecuador_c datesp, lwidth(thick))            ///
       (line Mexico_c datesp, lwidth(thick))             ///
       (line Nicaragua_c datesp, lwidth(thick))          ///
	   (line Peru_c datesp, lwidth(thick))               ///
		, title( Casos confirmados de Covid-19 en Latinoamérica)    ///
		subtitle(Contagios a la fecha)    				 ///
		ytitle( Cantidad de casos)				  		 ///
		xtitle (Fecha)							  		 ///
		ylabel(, angle(horizontal) format(%12,0gc))

		
*********************************************************	 
* Podemos ver los casos nuevos para estos paises

twoway (line Argentina_n datesp, lwidth(thick))          ///
       (line Brazil_n datesp, lwidth(thick))             ///
	   (line Chile_n datesp, lwidth(thick))              ///
       (line Colombia_n datesp, lwidth(thick))           ///
       (line Ecuador_n datesp, lwidth(thick))            ///
       (line Mexico_n datesp, lwidth(thick))             ///
       (line Nicaragua_n datesp, lwidth(thick))          ///
	   (line Peru_n datesp, lwidth(thick))               ///
		, title( Casos confirmados de Covid-19 en Latinoamérica)    ///
		subtitle(Contagios a fecha 12 de Abril)			 ///
		ytitle( Cantidad de casos)				  		 ///
		xtitle (Fecha)							  		 ///
		ylabel(, angle(horizontal) format(%12,0gc))

*Sacare Nicaragua y Brazil

twoway (line Argentina_n datesp, lwidth(thick))          ///
	   (line Chile_n datesp, lwidth(thick))              ///
       (line Colombia_n datesp, lwidth(thick))           ///
       (line Ecuador_n datesp, lwidth(thick))            ///
       (line Mexico_n datesp, lwidth(thick))             ///
	   (line Peru_n datesp, lwidth(thick))               ///
		, title( Nuevos casos diarios de Covid-19 en Latinoamérica)    ///
		subtitle(Casos nuevos 12 de Abril)    			 ///
		ytitle( Cantidad de casos nuevos)				 ///
		xtitle (Fecha)							 		 ///
		ylabel(, angle(horizontal) format(%12,0gc))	
		
*Ecuador muestra un aumento de 2196 nuevos contagios del 9 al 10 de Abril. 
*mientras dque del 10 al 11 de Abril solo 96 nuevos casos

**********GRAFICA DE BARRAS DE NUEVOS CASOS**************
*********************************************************
graph hbar (last) Argentina_n Brazil_n  Chile_n Colombia_n Ecuador_n Mexico_n Peru_n, bar(1, fcolor(blue)) bar(2, fcolor(dkgreen)) bar(3, fcolor(red)) bar(5, fcolor(navy)) blabel(total) ytitle(Cantidad de nuevos casos) title(Nuevos casos diarios de Covid-19 en Latinoamerica) subtitle(con fecha 12 de Abril) legend(on order(1 "Argentina" 2 "Brasil" 3 "Chile" 4 "Colombia" 5 "Ecuador" 6 "Mexico" 7 "Peru")) scale(1)

**********GRAFICA POR MILLON DE HABITANTES **************
*********************************************************
generate Argentina_ca = Chile_c /18.1
generate Chile_ca = Chile_c /18.1
generate Colombia_ca = Colombia_c /48.6
generate Ecuador_ca = Ecuador_c /16.7
generate Mexico_ca = Mexico_c / 127.3
generate Peru_ca = Peru_c / 31.6

label var Argentina_ca "Argentina"
label var Chile_ca "Chile"
label var Colombia_ca "Colombia"
label var Ecuador_ca "Ecuador"
label var Mexico_ca "Mexico"
label var Peru_ca "Peru"

*Graficamos

twoway (line Argentina_ca datesp, lwidth(thick))          	///
       (line Chile_ca datesp, lwidth(thick))          		///
       (line Colombia_ca datesp, lwidth(thick))        		///
       (line Ecuador_ca datesp, lwidth(thick))        		///
       (line Mexico_ca datesp, lwidth(thick))         		///
	   (line Peru_ca datesp, lwidth(thick))         		///
		, title( Casos confirmados de Covid-19 en Latinoamerica)    ///
		subtitle(por millón de habitantes)    				///
		ytitle( Cantidad de casos por millón)				///
		xtitle (Fecha)						   				///
		ylabel(, angle(horizontal) format(%12,0gc))
	
	*Declaramos los datos de series de tiempo
tsset datesp, daily    

*Guardamos la base wide
save covid19_wide2, replace 	

log close
