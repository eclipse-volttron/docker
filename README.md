# VOLTTRON Docker Image

This is the readme for the VOLTTRON docker repository.  The readme gives commands for starting a minimal volttron
environment (one without any agents) through to initializing the full environment using custom configuration and
datavolumes.  The readme will also walk through how the docker image is meant to be run, the environmental variables
available for changing behaviour and the assumptions that have been made in developing this image.

## Prerequisites

The following requires docker to be available through the command line and sudo to be available if you need to mount/remove datavolumes to persist files on host machine.

Clone this repository ```git clone https://github.com/eclipse-volttron/docker``` and ```cd docker```.

It is assumed that you are executing from a shell within the cloned docker directory for the rest of this README.


## Environmental Variables

The following environmental variables are available within the docker image.  One can set them using 
```docker exec -e "ENV=VAL" -u volttron ...``` where ```ENV``` is the environmental variable name with the 
value ```VAL```

| Environmental Variable        | Notes                                                                           |
| ----------------------        | ------------------------------------------------------------------------------- |
| PLATFORM_CONFIG=path        | Location of the platform configuration file to add agents during startup and setup the platform runtime.|
| REINITIALIZE=1           | If present the start up of the platform will always reinstall the platform and agents.  If not present the content in the passed datavolume will be utilized.  |


## Minimal Execution

This setup is to run a VOLTTRON instance directly from docker.  This will create a running volttron, but will not
persist on the host after the container stops.

```bash
# Starts a volttron in the background
docker run -d --name volttron --rm -it eclipsevolttron/volttron:v10
```

```bash
# View the logs. add --follow to keep the logs outputing.
docker logs volttron
```

```bash
# run a single volttron command from the command line
docker exec --user volttron -it volttron vctl status
```

```bash
# creates a bash shell inside the container. 
docker exec --user volttron -it volttron bash

# Now you are in the docker container and can run any volttron commands/restart volttron
vctl status

vctl install volttron-listener

vctl status

vctl shutdown --platform
```

## Persisting the VOLTTRON data 

Creating a datavolume allows a container to maintain its state over docker container restarts.  The
volttron container stores it's state in a directory /home/volttron/datavolume within the docker container. 
This directory can be mounted on the host by adding a -v option to the ```docker run``` command. 

The command below will create a directory on the host called $PWD/datavolume (if it doesn't exist)
and will use it for maintaining a VOLTTRON_HOME and a virtual environment that is used inside the container.

```bash
# Allow the datavolume (contains VOLTTRON_HOME and virtual environment) to
# be persisted to the host.
docker run -d -v $PWD/datavolume:/home/volttron/datavolume \
    --name volttron --rm -it eclipsevolttron/volttron:v10
```

## Initialization of Platform

Initialization of the platform requires getting platform and agent configurations to the docker container so that 
VOLTTRON can be configured with it.  To do this a second mount point is specified using the flags ```-v $PWD/example/config:/config```.
This will mount the contents on the host at $PWD/examples/config to the point inside the container /config.  The 
environmental variable ```-e 'PLATFORM_CONFIG=/config/example_platform_config.yml'``` informs the volttron container where its configuration file for the platform is located.  Note that this is from the containers perspective not the host.
In addition ```-e REINITIALIZE=1``` will remove existing volttron and agents inside the container and reinitialize volttron with a clean volttron home.

```bash
# Starts a volttron persisting volttron home.
docker run -d -v $PWD/example/config:/config \
    -v $PWD/datavolume:/home/volttron/datavolume \
    -e 'PLATFORM_CONFIG=/config/example_platform_config.yml' \
    --name volttron --rm -it eclipsevolttron/volttron:v10
```

Once the above command is run, you can monitor the logs via ```docker logs volttron``` or through another monitoring tool such as docker desktop or podman. Docker logs are located in ```/home/volttron/datavolume/volttron_home/volttron.log".


## Platform Config Structure

The platform config structure is as follows.  One can find this in the ```volttron-core/docker/example/config/example_platform_config.yml``` file referenced
above.  The structure is used for installation of services (server-side components such as web services) and agents (installed against an executing volttron).  


```
# Properties to be added to the root config file
# the properties should be ingestible for volttron
# the values will be presented in the config file
# as key=value
config:
  vip-address: tcp://0.0.0.0:22916
  instance-name: volttron1

services:
  volttron.services.web:
    libraries: 
      - volttron-lib-web
    enabled: true
    kwargs:
      bind_web_address: http://127.0.0.1:8080
      # Since http we need a web_secret_key for authentication
      web_secret_key: "A secret hasher"

# Agents dictionary to install. The key must be a valid
# identity for the agent to be installed correctly.
agents:

  # Each agent identity.config file should be in the configs
  # directory and will be used to install the agent.
  listener:
    source: volttron-listener
    tag: listener

  platform.driver:
    source: volttron-platform-driver
    libraries:
      - volttron-lib-fake-driver
      - volttron-lib-base-driver
    # Config store entries are able to be programatically looked up
    # by a key.  In the following there are two entries
    # - fake.csv
    # - devices/fake-campus/fake-building/fake-device
    #
    # The contents of the file will be available at the specific
    # key during runtime.
    config_store:
      fake.csv:
        file: platform.driver/fake.csv
        type: --csv
      devices/fake-campus/fake-building/fake-device:
        file: platform.driver/fake.json
        type: --json
    tag: driver
```
