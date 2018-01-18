#!/bin/bash
# Salir del script si alguna de las ejecuciones falla.
set -e


##################################################################################################################################
##################################################### Parametros por defecto #####################################################
##################################################################################################################################

# Parámetro que indica el directorio en que se va a trabajar.
WORKING_DIRECTORY=/tmp/CNVR

# Parámetro que indica el directorio en que se va a tener la ID del servidor (info).
DATA_DIRECTORY=$WORKING_DIRECTORY/z1

# Recogemos el nombre del hostname donde se ejecuta el script.
HOSTNAME="$(hostname)"

# Recogemos la IP del host.
HOST_IP="$(hostname -I)"

# El hostname es de la forma "zkX" siendo X el numero identificador del servidor Zookeeper. Recortamos la parte de la ID.
MY_ID=${HOSTNAME:2}

# Listado de las IPs de los dispositivos conectados a la misma red que el HOST.
# El resultado de IPs es un array donde en la primera posicion se encuentran todas las IPs separadas por un retorno de carro.
IPs=$(arp-scan --localnet --numeric --quiet --ignoredups | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | awk '{print $1}')

# https://stackoverflow.com/questions/24628076/bash-convert-n-delimited-strings-into-array
# Para convertir IPs en un array que podamos recorrer normalmente hacemos lo siguiente:

# Guardamos el IFS actual
SAVEIFS=$IFS
IPs=($IPs)

# Restauramos el IFS
IFS=$SAVEIFS

# Imprimimos IPs de las IPs recuperadas por el comando y procesadas correctamente.
echo "IPs del router (primera) y de los servidores del entorno Zookeeper"
for (( i=0; i<${#IPs[@]}; i++ ))
do
	echo "$i: ${IPs[$i]}"
done

# La IP en la posicion 0 es la del router, la primera es la propia del HOST que deberemos sustituir por su IP.
IPs[1]=$(hostname -I)

# Imprimimos IPs nuevamente para comprobar que estan correctamente todas.
echo "IPs del router (primera) y de los servidores del entorno Zookeeper"
for (( i=0; i<${#IPs[@]}; i++ ))
do
        echo "$i: ${IPs[$i]}"
done

# Ordenamos numericamente las IPs.
IPs=( $( printf "%s\n" "${IPs[@]}" | sort -n ) )

# Imprimimos las IPs ordenadas numericamente.
echo "IPs del router (primera) y de los servidores del entorno Zookeeper"
for (( i=0; i<${#IPs[@]}; i++ ))
do
        echo "$i: ${IPs[$i]}"
done


##################################################################################################################################
##################################################################################################################################
##################################################################################################################################


##################################################################################################################################
###################################################### Funciones Auxiliares ######################################################
##################################################################################################################################

# Funcion para imprimir '=' hasta el final de la linea.
line () {
	for i in $(seq 1 $(stty size | cut -d' ' -f2)); do 
		echo -n "="
	done
	echo ""
}


##################################################################################################################################
##################################################################################################################################
##################################################################################################################################


##################################################################################################################################
############################################################## Main ##############################################################
##################################################################################################################################

# Creamos directorios necesarios.
mkdir -p $WORKING_DIRECTORY
mkdir -p $DATA_DIRECTORY

# Crear archivos de descripción de los hosts en el directorio de datos.
echo $MY_ID > $DATA_DIRECTORY/myid

# Mover al directorio de trabajo.
cd $WORKING_DIRECTORY

# Extraer tar.gz en el directorio de trabajo y eliminar tras descomprimir.
mv /zookeeper_ensemble/zk/zookeeper-3.4.10.tar.gz .
tar -zxvf zookeeper-3.4.10.tar.gz
rm -rf zookeeper-3.4.10.tar.gz

# Mover las librerias a la carpeta de Zookeeper.
mv /zookeeper_ensemble/lib/* $WORKING_DIRECTORY/zookeeper-3.4.10/lib/

# Mover fichero de configuración a la carpeta de Zookeeper
mv /zookeeper_ensemble/conf/localhost_zoo.cfg $WORKING_DIRECTORY/zookeeper-3.4.10/conf/

# Modifcamos el fichero de localhost_zoo.cfg con la configuracion de los servidores de la red.
sed -i "s#dataDir=DATA_DIRECTORY#dataDir=${DATA_DIRECTORY}#g" $WORKING_DIRECTORY/zookeeper-3.4.10/conf/localhost_zoo.cfg
sed -i "s/server.1=localhost:2888:3888/server.1=${IPs[1]}:2888:3888/g" $WORKING_DIRECTORY/zookeeper-3.4.10/conf/localhost_zoo.cfg
sed -i "s/server.2=localhost:2889:3889/server.2=${IPs[2]}:2889:3889/g" $WORKING_DIRECTORY/zookeeper-3.4.10/conf/localhost_zoo.cfg
sed -i "s/server.3=localhost:2890:3890/server.3=${IPs[3]}:2890:3890/g" $WORKING_DIRECTORY/zookeeper-3.4.10/conf/localhost_zoo.cfg

# Arrancar los servidores que conformarán el entorno zookeeper.
line
echo "Arrancando el servidor $MY_ID"
$WORKING_DIRECTORY/zookeeper-3.4.10/bin/zkServer.sh start $WORKING_DIRECTORY/zookeeper-3.4.10/conf/localhost_zoo.cfg

# Verificamos el estado de los servidores del entorno Zookeeper.
line
echo "El estado del servidor $MY_ID de Zookeeper:"
$WORKING_DIRECTORY/zookeeper-3.4.10/bin/zkServer.sh status $WORKING_DIRECTORY/zookeeper-3.4.10/conf/localhost_zoo.cfg

# Lanzar mensajes en consola con instrucciones de ejecución en varias terminales.
line
echo "Ejecutar los siguientes comandos para acceder a la CLI (Command Line Interface) de este servidor del conjunto Zookeeper:"
echo "$WORKING_DIRECTORY/zookeeper-3.4.10/bin/zkCli.sh -server localhost:2181"


##################################################################################################################################
##################################################################################################################################
##################################################################################################################################