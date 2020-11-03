#!/bin/bash
export DISPLAY=:99

LAT_V="$(wget -qO- https://github.com/ich777/versions/raw/master/FerdiClient | grep LATEST | cut -d '=' -f2)"
CUR_V="$(find ${DATA_DIR} -name "ferdiclient-*" | cut -d '-' -f2)"

if [ -z $LAT_V ]; then
    if [ -z $CUR_V ]; then
        echo "---Can't get latest version of Ferdi-Client, putting container into sleep mode!---"
        sleep infinity
    else
        echo "---Can't get latest version of Ferdi-Client, falling back to v$CUR_V---"
    fi
fi

if [ -f ${DATA_DIR}/FerdiClient-v$LAT_V.tar.gz ]; then
	rm -rf ${DATA_DIR}/FerdiClient-v$LAT_V.tar.gz
fi

echo "---Version Check---"
if [ -z "$CUR_V" ]; then
    echo "---Ferdi-Client not found, downloading and installing v$LAT_V...---"
    cd ${DATA_DIR}
    if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/FerdiClient-v$LAT_V.tar.gz "https://github.com/getferdi/ferdi/releases/download/v${LAT_V}/ferdi-${LAT_V}.tar.gz" ; then
        echo "---Successfully downloaded Ferdi-Client v$LAT_V---"
    else
        echo "---Something went wrong, can't download Ferdi-Client v$LAT_V, putting container into sleep mode!---"
        sleep infinity
    fi
    tar -C ${DATA_DIR} --strip-components=1 -xf ${DATA_DIR}/FerdiClient-v$LAT_V.tar.gz
	touch ferdiclient-$LAT_V
    rm ${DATA_DIR}/FerdiClient-v$LAT_V.tar.gz
elif [ "$CUR_V" != "$LAT_V" ]; then
    echo "---Version missmatch, installed v$CUR_V, downloading and installing v$LAT_V...---"
    cd ${DATA_DIR}
	rm -rf ${DATA_DIR}/*
    if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/FerdiClient-v$LAT_V.tar.gz "https://github.com/getferdi/ferdi/releases/download/v${LAT_V}/ferdi-${LAT_V}.tar.gz" ; then
        echo "---Successfully downloaded Ferdi-Client v$LAT_V---"
    else
        echo "---Something went wrong, can't download Ferdi-Client v$LAT_V, putting container into sleep mode!---"
        sleep infinity
    fi
    tar -C ${DATA_DIR} --strip-components=1 -xf ${DATA_DIR}/FerdiClient-v$LAT_V.tar.gz
	touch ferdiclient-$LAT_V
    rm ${DATA_DIR}/FerdiClient-v$LAT_V.tar.gz
elif [ "$CUR_V" == "$LAT_V" ]; then
    echo "---nzbget v$CUR_V up-to-date---"
fi

echo "---Preparing Server---"
echo "---Resolution check---"
if [ -z "${CUSTOM_RES_W} ]; then
	CUSTOM_RES_W=1024
fi
if [ -z "${CUSTOM_RES_H} ]; then
	CUSTOM_RES_H=768
fi

if [ "${CUSTOM_RES_W}" -le 1023 ]; then
	echo "---Width to low must be a minimal of 1024 pixels, correcting to 1024...---"
    CUSTOM_RES_W=1024
fi
if [ "${CUSTOM_RES_H}" -le 767 ]; then
	echo "---Height to low must be a minimal of 768 pixels, correcting to 768...---"
    CUSTOM_RES_H=768
fi
echo "---Checking for old logfiles---"
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;
echo "---Checking for old display lock files---"
find /tmp -name ".X99*" -exec rm -f {} \; > /dev/null 2>&1
screen -wipe 2&>/dev/null

chmod -R ${DATA_PERM} ${DATA_DIR}

echo "---Starting Xvfb server---"
screen -S Xvfb -L -Logfile ${DATA_DIR}/XvfbLog.0 -d -m /opt/scripts/start-Xvfb.sh
sleep 2
echo "---Starting x11vnc server---"
screen -S x11vnc -L -Logfile ${DATA_DIR}/x11vncLog.0 -d -m /opt/scripts/start-x11.sh
sleep 2
echo "---Starting Fluxbox---"
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2
echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem 8080 localhost:${X11-PORT}
sleep 2

echo "---Starting Ferdi-Client---"
cd ${DATA_DIR}
${DATA_DIR}/ferdi --no-sandbox 2>/dev/null