## Supported tags and respective `Dockerfile` links
* `latest` ([Dockerfile](https://github.com/XMRto/tor/blob/master/Dockerfile))

---

This image contains Tor.

There are serveral use cases for this image:
* Other services can be made available through the Tor network.
* Clients can interact through the Tor network.

## Things to know

The docker image contains the default `/etc/tor/torrc` configuration file - Everything is commented.

* You can use a custom `torrc` configuration file - assuming you have a local file called `torrc`.
  - This can be mounted into the container using `-v $PWD/torrc:/etc/tor/torrc`

This is no guide for Tor proxy security best practices. Please refer to other resources.

## Basic usage
Use a custom `torrc` and mount a local folder (containing `hostname` and `private_key` files) into the container:
```
docker run -d --name tor_proxy --net host -v $(pwd)/torrc:/etc/tor/torrc -v $PWD/daemons:/var/lib/tor/daemons xmrto/tor
```

It's also possible to configure `tor` more dynamically by passing `hostname` and `private_key` as environment variables like this:
```
docker run -d --name tor_proxy --net host -e HOSTNAME=<your_hostname.onion> -e PRIVATE_KEY=<yout_private_key> -e SERVICE_PORT=8000 -e SERVICE_NAME=some_hidden_service xmrto/tor
```

For more details, please see below.

## Run services within the Tor network

Suppose you have a service running on port `8000`.

You can make it available over Tor.

The example `torrc` configuration below binds Tor to `0.0.0.0` and exposes Tor on port `9050` to make it available in the Tor network. This allows access to Tor, when Tor is running within a docker container.
The Socks policy rejects every SOCKS request - No client can interact using the SOCKS protocol.

The example `torrc` configuration file below sets `/var/lib/tor` as Tor data directory. It also configures `/var/lib/tor/service` as the directory for the hidden service. Also our service on port `8000` should be available on port `8080` in the Tor network.
If you don't supply a `hostname` and an appropriate `private_key` file, Tor will generate them itself within the **HiddenServiceDir** directory. These files will be created anew every time the container starts, except you persist them using a docker volume (For persisting the onoin service hostname, please see **Dynamic hostname and private keys**).

```
SOCKSPort 0.0.0.0:9050
SOCKSPolicy "reject *"

HiddenServiceDir /var/lib/tor/service/
HiddenServicePort 8080 127.0.0.1:8000

DataDirectory /var/lib/tor
Log notice file /var/log/tor/notices.log
```

Finally, the Tor container can be started.
The docker option `--net host` makes the host's localhost available in the Tor docker container. This makes it possible to configure the Tor **HiddenServicePort** to `127.0.0.1:8000`, in order to access the service.

```
docker run -d --name tor_proxy --net host -v $(pwd)/torrc:/etc/tor/torrc xmrto/tor
```

You can read the Tor **.onion** address from `hostname` like this (`tor_proxy` is the container's name):

`docker exec tor_proxy cat /var/lib/tor/service/hostname`

If you already have `hostname` and an according `private_key` file, you can mount them into the container like you would mount the `torrc` file - assuming they are in a local folder called `service`.

```
docker run -d --name tor_proxy --net host -v $(pwd)/torrc:/etc/tor/torrc -v $PWD/service:/var/lib/tor/service xmrto/tor
```


## Use clients through the Tor network

To make use of the Tor proxy locally and let clients use it, check the following setup.

`torrc` configuration file:

```
SOCKSPort 0.0.0.0:9050

Log notice file /var/log/tor/notices.log

```

Run the tor docker container. In this case no hidden sevrice is hosted. Also the Tor container does not need any access to localhost - The host's localhost is not shared with the docker container. Instead the Tor Socks Port is published to the host using `-p 9050:9050`.

```
docker run -d --name tor_proxy -p 9050:9050 -v $PWD/torrc:/etc/tor/torrc xmrto/tor
```

Using [`torsocks`](https://trac.torproject.org/projects/tor/wiki/doc/torsocks) to tunnel network traffic of any application through the Tor proxy:

```
torsocks [application]
``` 


## Example use with monero mainnet daemon

Let's assume that the monero mainnet daemon is running on the host bound to port `18081`.

`torrc` configuration file:

```
SOCKSPort 0.0.0.0:9050
# comment for local use with e.g. curl
SOCKSPolicy "reject *"

HiddenServiceDir /var/lib/tor/daemons/
HiddenServicePort 18181 127.0.0.1:18081

DataDirectory /var/lib/tor
Log notice file /var/log/tor/notices.log
```

Run the tor docker container - Making use of the host's localhost again (`--net host`). The folder `daemons` contains the files `hostname` and `private_key`.

```
docker run -d --name tor_proxy --net host -v $(pwd)/torrc:/etc/tor/torrc -v $PWD/daemons:/var/lib/tor/daemons xmrto/tor
```

In this example we provided a `hostname` file, but still we can retrieve the hostname as described.

`docker exec tor_proxy cat /var/lib/tor/daemons/hostname`

Let's assume the hostname is **<hostname.onion>**.

You can now connect your monero cli to the your monero mainnet daemon through the Tor network.

```
torsocks monero-wallet-cli --daemon-host <hostname.onion>:18181
```


## Create a hidden service's onion address

[eschalot](https://github.com/ReclaimYourPrivacy/eschalot) seems to be a very good tool to generate Tor onion addresses.

**eschalot** creates the file `hostname` containing a **.onion** address and a referring `private_key` file you need to supply when hosting a hidden service, that is supposed to keep its **.onion** address.

After installing it from source,you could execute the following command, in order to end up with a **.onion** address starting with `tor`.

```
./eschalot -t4 -v -c -p tor
# -t count: number of threads to spawn (4 cores in this case)
# -c: continue searching after the hash is found
# -v: verbose mode
# -p prefix: single prefix to look for ("tor" in this case)
```

## Dynamic hostname and private keys

Starting with docker image tag `v0.0.1`.

The configuraton described above is only one way to use this image - mounting a volume or local directory into the docker container like this:
```
docker run -d --name tor_proxy --net host -v $(pwd)/torrc:/etc/tor/torrc -v $PWD/daemons:/var/lib/tor/daemons xmrto/tor
```

It's also possible to configure `tor` more dynamically by passing `hostname` and `private_key` as environment variables like this:
```
docker run -d --name tor_proxy --net host -e HOSTNAME=<your_hostname.onion> -e PRIVATE_KEY=<yout_private_key> -e SERVICE_PORT=8000 -e SERVICE_NAME=some_hidden_service xmrto/tor
```

This way the following configuration will be createdon the fly:
```
SOCKSPort 0.0.0.0:9050
# comment for local use with e.g. curl
SOCKSPolicy "reject *"

HiddenServiceDir /var/lib/tor/some_hidden_service/
HiddenServicePort 8000 127.0.0.1:8000

DataDirectory /var/lib/tor
Log notice file /var/log/tor/notices.log
```

In addition the hidden service directory `/var/lib/tor/some_hidden_service` will be created and the files `/var/lib/tor/some_hidden_service/hostname` as well as `/var/lib/tor/some_hidden_service/private_key` will be created, too.

The defaulti environemnt variable `SERVICE_NAME` can also be left out - Its default value is `hidden_service`.
