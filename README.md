# focus-distrib
Public files for configuring a Focus deployment.

These files are provided for the purpose of configuring an Ubuntu Linux instance to host a
proprietary Docker image containing a version of the Focus software.

## Prerequisites

- You require a root login to a fresh Linux instance.
- If your intended domain name is, say, nvision.uk.com,
configure the domain A record to point to the IP address of your instance (IPv4 presently).

## Prepare the application

Prepare you Ubuntu instance as follows:
- log in as root
- run the command `sudo apt update`
- install Docker with the command `apt install docker.io certbot`
- configure your SSL certificate with `sudo certbot certonly --standalone -d yourdomain.com`
- paste the following command into your terminal session and execute it:

`sudo groupadd -g 1000 focusgroup 2>/dev/null || echo "Group ID 1000 already exists."; useradd -u 1000 -g focusgroup -m focus 2>/dev/null || echo "User ID 1000 already exists."; mkdir -p /app; cd /app; [ ! -d "/app/focus-distrib" ] && git clone https://github.com/rtc-focus-org/focus-distrib.git || echo "Repository already cloned."; mkdir -p /app/focus-distrib/dav /app/focus-distrib/db /app/focus-distrib/logs/supervisor; chown -R focus:focusgroup /app; cd /app/focus-distrib; echo "Script execution completed."`

You should find it has created a `/app` folder filled with the contents of this github repository and three folders dav, db and logs that by default will be used to store your user files, database and server logs respectively.

This means that your system disk will contain production data and must be backed up regularly. For more resilience you will need to adapt your configuration as described below (t.b.a.)

Your current working directory should now be `/app/focus-distrib`

## Configure the application

### `app.env`

Create the file app.env to contain the necessary secrets for your configuration

### `env.sh`

This file should contain four lines as follows:
```
FOCUS_VERSION=0.0.0
FOCUS_IDENTITY=app
FOCUS_DOMAIN=your domain
DOCKER_PULL_PASSWORD=the Docker password to fetch the container image
```

### Running the container

Execute the command `docker_run.sh`

The container should now be running as another Linux system inside the running instance.

### Prepare the database and static assets

Log in to a shell inside the container with the command

`docker exec -it focus bash`

Inside the shell execute these commands:

```
dj migrate
dj collectstatic
dj makeBareDatabase
exit
```

Your system should now be up and running at https://your-domain/ui

The makeBareDatabase command does several things:
- creates a superuser with the username and password specified in your app.env
- creates an account called `demo` with a meeting and some invitations ready to go
- creates a user for that account called `demo_client` with manager status, but inactive. The user cannot log in until you set them active
by logging in as the superuser in the Django admin (https://your-domain/admin). You should change the password first.
Meantime you can operate the account with the superuser login.

### Stopping your container

To stop your container:
`docker stop focus`
