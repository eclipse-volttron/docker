
set -eu

if [ ! -d $VOLTTRON_HOME ]
then
    mkdir -p $VOLTTRON_HOME
fi

if [ ! -d $VOLTTRON_VENV ]
then
    mkdir -p $VOLTTRON_VENV
fi

chown -R volttron:volttron $VOLTTRON_DATA_VOLUME
#chown -R volttron:volttron /startup
#pwd
#ls -la

# this needs to be set since we write to the home directory for instances.
export HOME=/home/volttron
cd /home/volttron

REINITIALIZE="${REINITIALIZE:=0}"

if [ $REINITIALIZE != 0 ]
then
    if [ -d "${VOLTTRON_HOME}" ]
    then
        echo "Reinitializing"
        rm "${VOLTTRON_HOME}" -rf
    fi
fi


if [ ! -f "$VOLTTRON_HOME/initialized" ]
then
    #su -m volttron -c "python /startup/setup-platform.py"
    exec runuser -u volttron -- python /startup/setup-platform.py
fi


if [ ! $@ ]
then
    exec runuser -u volttron -- volttron -v
else
    exec runuser -u volttron -- "$@"
fi