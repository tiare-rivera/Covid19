* ===================================================================================================
* Fecha: 12 Abril 2020
* Objetivo: Limpieza de datos y analisis de estadisticas Covid19
* Fuente de datos: Github Johns Hopkins University
*
* Adaptacion de: Chuck Huber, Associate Director of Statistical Outreach, STATA Corp.
*Version de: Tiare Rivera
*
* Variables clave: 
*          - Numero de contagiados.
*		   - Numero de muertes.
*		   - Numero de recuperados.
* 
* ===================================================================================================

* setup
capture log close
set more off 

*open log file 
log using covid19_TRT, replace text 

clear all

**********IMPORTAR UNA TABLA CSV *******
****************************************
*Primero importamos un csv, con la precaucion de arrglar los
*caracteres que estan malos (encoding)

import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/01-29-2020.csv", encoding(utf-8)

describe
list in 1/5

**USANDO MACROS PARA IMPORTAR DIFERENTES ARCHIVOS *******
*********************************************************
**Global macro:  Disponible en todo STATA
**Local macro: Disponible solo en el do file

// Creamos locales de locales, primero la fecha y luego la URL

*********************** EJEMPLO ************************
local month= string(3, "%02.0f")
* indica que el dia 3 tendra antes del punto un cero previo, dos cifras y 
*despues del punto cero decimales.

local day= string(19, "%02.0f")
*Antes del punto, habran dos cifras (19) y despues del punto cero decimales

local year = "2020"

local today = "`month'-`day'-`year'"

display "`today'"

// Ahora la URL

local URL = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/"
display "`URL'"

//Importamos la data usando FileName como nombre de archivo
clear
local FileName = "`URL'`today'.csv"
import delimited "`FileName'", encoding(utf-8)
describe

**USANDO LOOPS PARA IMPORTAR DIFERENTES ARCHIVOS *******
*********************************************************
forvalues month =1/12{
	display "month = `month'"
}
* Puedo llamar a la macro local

// También se puede hacer un loop dentro de un loop.
// Un loop de dias dentro de los meses

*********************** EJEMPLO *************************
*********************************************************
forvalues month = 1/12{
	forvalues day = 1/31{
		display "month = `month', day = `day'"
	}
}

****************** NOMBRES DE ARCHIVOS******************
** Ahora creamos los nombres de archivos que se desea descargar

forvalues month = 1/12 {
    forvalues day = 1/31 {
        local month = string(`month', "%02.0f") 
        local day   = string(`day', "%02.0f") 
        local year  = "2020"
        local today = "`month'-`day'-`year'"
        display "`today'"
    }
}

***Traemos con la URL la data de todos los dias (tiempo varios minutos)
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
        capture save "`today'", replace
    }
}

*********************RENOMBRAR VARIABLES ****************
*********************************************************
//Lo hacemos con un loop, con la precaucion de unir las variables
//que cambiaron de nombre. Capture es para seguir corriendo en caso
//de ausencia de datos.

local URL = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/"
forvalues month = 1/12 {
    forvalues day = 1/31 {
        local month = string(`month', "%02.0f") 
        local day   = string(`day', "%02.0f") 
        local year  = "2020"
        local today = "`month'-`day'-`year'"
        local FileName = "`URL'`today'.csv"
        clear
        capture import delimited "`FileName'", encoding(utf-8)
		capture rename province_state provincestate
		capture rename country_region countryregion
		capture rename last_update lastupdate
		capture rename lat latitude
		capture rename long longitude
        capture save "`today'", replace
    }
}
** Usamos save para no tener que renombrar las variables constantemente

// Verificamos que los nombres coincidan
describe using 03-21-2020.dta
describe using 03-22-2020.dta

// Verificamos que se unieron correctamente
clear
append using 03-21-2020.dta
append using 03-22-2020.dta
describe


*****************UNIR LAS BASES DE DATOS ****************
*********************************************************
// Usamos un loop para renombrar las variables
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

describe

*****************PROBLEMAS CON LASTUPDATE****************
*********************************************************
//Vemos que las primeras observaciones no son iguales a las
//ultimas observaciones, cambiaron el formato.

list lastupdate in 1/5
list lastupdate in -5/l

// Como solucion, se genera una variable llamada "tempdate"
// que dejara en el mismo formato que today:

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

**Revisamos
list tempdate in 1/5
list tempdate in -5/l

** Pero siguen en formato texto, ahora debemos pasarlo a fecha

*********************** EJEMPLO *************************
*********************************************************
**Si se usara solamente la funcion date, entregaria el numero de dias
**desde el 1 de enero de 1960
display date("03-23-2020", "MDY")

*Esto no sirve, por tanto hay que dar formato a la fecha
*Con Mes Dia Anio (MDY)

display %tdNN/DD/CCYY date("03-23-2020", "MDY")

*****************GENERAR FECHA***************************
*********************************************************
generate date = date(tempdate, "MDY")

*revisamos las ultimas 5 filas
list lastupdate tempdate date in -5/l

*Le damos formato a date
format date %tdNN/DD/CCYY

*Formato de fecha europeo
generate datesp =date(tempdate, "MDY")
format datesp %tdDD/NN/CCYY

**Revisamos 
list lastupdate tempdate date datesp in -5/l, clean

**Grabamos la dataset
save covid19_date, replace

*****************TIME SERIES*****************************
*********************************************************
use covid19_date, clear
keep if countryregion =="Chile"

*vemos que el primer caso de coronavirus en Chile fue el 3 de marzo
*y que el 5 de marzo ya habian 4 casos, si lo vemos en detalle

list date confirmed deaths recovered           ///
     if date==date("3/13/2020", "MDY"), abbreviate(13)

*En el caso chileno los datos estan colapsados, pero en el caso US no
*Veamos el caso US

use covid19_date, clear
keep if countryregion=="US"

*vemos que la fecha 26 de Enero esta desagregada en 4 observaciones
list date confirmed deaths recovered           ///
     if date==date("1/26/2020", "MDY"), abbreviate(13)

*Usamos collapse y chequeamos nuevamente
collapse (sum) confirmed deaths recovered, by(date)

*revisamos
list date confirmed deaths recovered           ///
     if date==date("1/26/2020", "MDY"), abbreviate(13)

*Hacemos collapse para todos los paises, empezamos de nuevo
*usando la fecha en formato europeo

use covid19_date, clear
collapse (sum) confirmed deaths recovered, by(datesp)

*revisamos
describe 
list in 1/5, abbreviate(9)

**Pondremos un formato con numeros y permitiremos que la cifra sea
*mas grande

format %12,0gc confirmed deaths recovered
list, abbreviate(9) 
	 

*************DECLARAMOS TIME SERIES**********************
*********************************************************	 
tsset datesp, daily

*Graficas generales
twoway (tsline confirmed) 
twoway (tsline deaths)   
twoway (tsline confirmed, recast(bar))	 
	 
**Generamos nuevos casos
generate nuevoscasos = D.confirmed	 
twoway (tsline nuevoscasos)
	 
*******************DIFERENTES PAISES*********************
*********************************************************	 
use covid19_date, clear 
	 
tab countryregion

*Vemos que China esta dos veces, como Mailand China.

replace countryregion = "China" if countryregion =="Mainland China"	 

*Vamos a mantener las observaciones de China, Italia, US y Chile
keep if inlist(countryregion, "China", "US", "Italy", "Chile", "Spain", "Ecuador")

tab countryregion

*Hacemos un collapse tanto para fecha como pais
collapse (sum) confirmed deaths recovered, by(datesp countryregion)

list date countryregion confirmed deaths recovered /// 
     in -9/l, sepby(datesp) abbreviate(13) 
* Ahora hay una observacion para cada fecha de cada pais

**Se necesitara usar a pais como valor numerico, usaremos encode
encode countryregion, gen(pais)

*revisamos
list datesp countryregion pais  ///
      in -9/l, sepby(datesp) abbreviate(13)

*vemos que se ven igual, pero pais ahora tiene formato numerico
*podemos ver las categorias

label list pais

*Podemos decirle a STATA que ahora tenemos datos de series de tiempo
*con paneles, que son los paises

tsset pais datesp, daily

*Grabamos esta nueva version 
save covide19_long

*************************RESHAPE*************************
*********************************************************
* Lo dejaremos en un formato wide para dejar la informacion de cada
* pais lado a lado. Vamos a dejar solo las variables que nos interesan
use covid19_long, clear

keep datesp pais confirmed deaths recovered

* reshape los datos de "long" a "wide"
reshape wide confirmed deaths recovered, i(datesp) j(pais)
* Vemos que pasamos de 387 observaciones a 81
* Pasamos de 5 varialbes a 19
* Se elimino pais
* Tenemos confirmados1,2 etc por cada pais
* Lo mismo para deaths y recovered

describe

*Revisamos la informacion

list datesp confirmed1 confirmed2 confirmed3 confirmed4 confirmed5 confirmed6   ///
     in -5/l, abbreviate(13)

*************************RENAME Y LABEL******************
*********************************************************
* Vamos a cambiar los nombres por:
* _c para casos confirmados
* _d para muertes
* _r para casos recuperados

*1 Chile
*2 China
*3 Ecuador
*4 Italy
*5 Spain
*6 US

*Loop para renombrar los confirmados
local vars1 "confirmed1 confirmed2 confirmed3 confirmed4 confirmed5 confirmed6"
local vars2 "Chile_c China_c Ecuador_c Italia_c Espana_c USA_c"
local n: word count `vars1'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
rename `v1' `v2'
}

*Loop para poner label a las variables de confirmados
local vars1 `" "Chile_c" "China_c" "Ecuador_c" "Italia_c" "Espana_c" "USA_c" "'
local vars2 `" "Contagios Chile" "Contagios China" "Contagios Ecuador" "Contagios Italia" "Contagios España" "Contagios USA"  "'
local n: word count `vars2'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
label var `v1' "`v2'"
}


*Loop para renombrar las muertes
local vars1 "deaths1 deaths2 deaths3 deaths4 deaths5 deaths6"
local vars2 "Chile_d China_d Ecuador_d Italia_d Espana_d USA_d"
local n: word count `vars1'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
rename `v1' `v2'
}

*Loop para poner label a las muertes
local vars1 `" "Chile_d" "China_d" "Ecuador_d" "Italia_d" "Espana_d" "USA_d" "'
local vars2 `" "Muertes Chile" "Muertes China" "Muertes Ecuador" "Muertes Italia" "Muertes España" "Muertes USA"  "'
local n: word count `vars2'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
label var `v1' "`v2'"
}

*Loop para renombrar los recuperados
local vars1 "recovered1 recovered2 recovered3 recovered4 recovered5 recovered6"
local vars2 "Chile_r China_r Ecuador_r Italia_r Espana_r USA_r"
local n: word count `vars1'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
rename `v1' `v2'
}

*Loop para poner label a los recuperados
local vars1 `" "Chile_r" "China_r" "Ecuador_r" "Italia_r" "Espana_r" "USA_r" "'
local vars2 `" "Recuperados Chile" "Recuperados China" "Recuperados Ecuador" "Recuperados Italia" "Recuperados España" "Recuperados USA"  "'
local n: word count `vars2'
forvalues i = 1/`n' {
local v1 : word `i' of `vars1'
local v2 : word `i' of `vars2'
label var `v1' "`v2'"
}

*revisamos
describe

list datesp Chile_c China_c Ecuador_c  Italia_c  Espana_c USA_c   ///
     in -5/l, abbreviate(13)

*************************GRAFICAR************************
*********************************************************	 
* Podemos ver los casos confirmados diarios para estos paises

twoway (line Chile_c datesp, lwidth(thick))          ///
       (line China_c datesp, lwidth(thick))          ///
       (line Ecuador_c datesp, lwidth(thick))        ///
       (line Italia_c datesp, lwidth(thick))         ///
       (line Espana_c datesp, lwidth(thick))         ///
		, title( Casos confirmados de Covid-19)      ///
		subtitle(Contagios diarios)    				 ///
		ytitle( Cantidad de casos)			   	   ///
		xtitle (Fecha)							    ///
		ylabel(, angle(horizontal) format(%12,0gc))

		
*Para agregar Estados Unidos:
* *      (line USA_c date, lwidth(thick))            ///

**********GRAFICA POR MILLON DE HABITANTES **************
*********************************************************
generate Chile_ca = Chile_c /18.1
generate China_ca = China_c /1389.6
generate Ecuador_ca = Ecuador_c /16.7
generate Italia_ca = Italia_c / 62.3
generate Espana_ca = Espana_c / 49.7
generate USA_ca = USA_c / 331.8

label var Chile_ca "Casos de Chile"
label var China_ca "Casos de China"
label var Ecuador_ca "Casos de Ecuador"
label var Italia_ca "Casos de Italia"
label var Espana_ca "Casos de España"
label var USA_ca "Casos de USA"

*Graficamos

twoway (line Chile_ca datesp, lwidth(thick))          ///
       (line China_ca datesp, lwidth(thick))          ///
       (line Ecuador_ca datesp, lwidth(thick))        ///
       (line Italia_ca datesp, lwidth(thick))         ///
       (line Espana_ca datesp, lwidth(thick))         ///
		, title( Casos confirmados de Covid-19)   	  ///
		subtitle(por millón de habitantes)    		  ///
		ytitle( Cantidad de casos por millón)		  ///
		xtitle (Fecha)							      ///
		ylabel(, angle(horizontal) format(%12,0gc))

*Dejamos menos paises

twoway (line USA_ca datesp, lwidth(thick))            ///
       (line China_ca datesp, lwidth(thick))          ///
       (line Italia_ca datesp, lwidth(thick))         ///
		(line Espana_ca datesp, lwidth(thick))        ///
		, title( Casos confirmados de Covid-19)    	  ///
		subtitle(por millón de habitantes)    		  ///
		ytitle( Cantidad de casos por millón)		  ///
		xtitle (Fecha)							      ///
		ylabel(, angle(horizontal) format(%12,0gc))

*Para latinoamerica
twoway (line Chile_ca datesp, lwidth(thick))          ///
       (line Ecuador_ca datesp, lwidth(thick))        ///
		, title( Casos confirmados de Covid-19)    	  ///
		subtitle(por millón de habitantes)            ///
		ytitle( Cantidad de casos por millón)		  ///
		xtitle (Fecha)							      ///
		ylabel(, angle(horizontal) format(%12,0gc))

*Agregamos notas
notes Chile_ca: Chile_ca = Chile_c / 18.1
notes Chile_ca: Fuente de poblacion: https://www.census.gov/popclock/
notes China_ca: China_ca = China_c / 1389.6
notes China_ca: Fuente de poblacion:: https://www.census.gov/popclock/
notes Ecuador_ca: Ecuador_ca = Ecuador_c / 16.7
notes Ecuador_ca: Fuente de poblacion:: https://www.census.gov/popclock/
notes Italia_ca: Italia_ca = Italia_c / 62.3
notes Italia_ca: Fuente de poblacion:: https://www.census.gov/popclock/
notes Espana_ca: Espana_ca = Espana_c / 49.7
notes Espana_ca: Fuente de poblacion:: https://www.census.gov/popclock/
notes USA_ca:   USA_ca = USA_c / 331.8
notes USA_ca:   Fuente de poblacion:: https://www.census.gov/popclock/    

*Agregamos notas a la base de datos:
label data "Analisis de datos para Covid19 2020"
notes _dta: Fuente de datos: https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_daily_reports
notes _dta: Estos datos son solo para propositos educacionales

*Se pueden ver aca
notes

*Declaramos los datos de series de tiempo
tsset date, daily    

*Guardamos la base wide
save covid19_wide, replace  


log close




