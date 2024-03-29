# focus-distrib
Public files for configuring a Focus deployment.

These files are provided for the purpose of configuring an Ubuntu Linux instance to host a
proprietary Docker image containing a version of the Focus software.

## Prerequisites

- You require a root login to a fresh Linux instance.
- If your intended domain name is, say, nvision.uk.com,
configure the domain A record to point to the IP address of your instance (IPv4 presently).
- Your host machine will need to have at least ports 22 (if you require SSH access), 80 (HTTP) and 443 (HTTPS) open for successful operation. This document does not discuss setting up a firewall on the host machine but limiting access to these ports is strongly recommended.
- Your host machine should operate this application exclusively

## Prepare the application

Prepare your Ubuntu instance as follows:
- log in:
  - as root (in which case sudo is redundant but harmless in the following commands) *OR*
  - as a sudo-capable user
- run the command `sudo apt update`
- install Docker with the command `apt install docker.io certbot`
- configure your SSL certificate with `sudo certbot certonly --standalone -d yourdomain.com`
- ensure your container will be able to read the certificate with
```sudo find /etc/letsencrypt/live/yourdomain.com -type f -exec chown 1000:1000 {} \;```
- paste the following command into your terminal session and execute it:

`sudo groupadd -g 1000 focusgroup 2>/dev/null || echo "Group ID 1000 already exists."; sudo useradd -u 1000 -g focusgroup -m focus 2>/dev/null || echo "User ID 1000 already exists."; sudo mkdir -p /var/app; cd /var/app; [ ! -d "/var/app/focus-distrib" ] && sudo git clone https://github.com/rtc-focus-org/focus-distrib.git || echo "Repository already cloned."; sudo mkdir -p /var/app/focus-distrib/dav /var/app/focus-distrib/db /var/app/focus-distrib/logs/supervisor; sudo chown -R 1000:1000 /var/app; cd /var/app/focus-distrib; echo "Script execution completed."`

You should find it has created a `/var/app` folder filled with the contents of this github repository and three folders dav, db and logs that by default will be used to store your user files, database and server logs respectively.

This means that your system disk will contain production data and must be backed up regularly. For more resilience you will need to adapt your configuration as described below (t.b.a.)

Your current working directory should now be `/var/app/focus-distrib`

The application processes in the container run in user mode, as user 1000. That is why it is necessary to set up files on your host machine that are owned by your local user 1000. 

## Configure the application

### Required files

#### `app.env`

Create the file app.env to contain the necessary secrets for your configuration. These are described in a separate section below.

#### `env.sh`

This file should contain four lines as follows:
```
FOCUS_VERSION=0.0.5
FOCUS_IDENTITY=app
FOCUS_DOMAIN=your domain
DOCKER_PULL_PASSWORD=the Docker password to fetch the container image
```

#### Google credentials file

This file is supplied by GCS as a JSON document with essential information including secrets for accessing the speech API.
When you have procured your document it should be saved in the file `/var/app/focus-distrib/gcs_speech_api.json`. Ensure
the file is owned by user 1000 with
```
sudo chown 1000:1000 /var/app/focus-distrib/gcs_speech_api.json
```

### Running the container

Execute the command `./docker_run.sh`

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

## Preparing the `app.env` file

This is in Docker .env format (https://docs.docker.com/compose/environment-variables/env-file/).
Note this is similar to the syntax for setting variables in a Linux shell script.
Be mindful of the interpretation of spaces, hash characters, and single and double quotes.

A file app_template.env is provided.
```
cp app.env_template app.env # then edit app.env
```

## Contents of `app_template.env`

```
# This file associates information specific to your server
# with particular parameter values needed for server operation

# All of the values need to be customised. Values that are
# not secret are taken from an existing site and left in plaintext for clarity.
# THEY ALL NEED TO BE CUSTOMISED CORRECTLY for the site to work.

# Strings of @@@ characters denote fields to
# replace with strings of your own choice which you should
# keep secret else risk unauthorised use of the server

# Strings of ### characters denote fields whose values
# are chosen by the various supplier portals. They need
# to be copied from those portals into this file. They
# must also be kept secret else risk unauthorised use
# of that supplier's resources at the expense of the account owner.

# Each line is either comment (begins #) or name=value
# Customise the value in each line and save the result as app.env, retaining
# this file unchanged for reference.

# This list of hosts (JSON format) should include your server's domain name and IP address
ALLOWED_HOSTS=["beta.dsxml.com","167.99.207.65"]
# This is your choice of secret to encrypt Django cookies
SECRET_KEY=#############

# Your Vonage project API key and secret from the Vonage portal
API_KEY=########
API_SECRET=##################

# Twilio details
TWILIO_ACCOUNT_SID=AC################
TWILIO_AUTH_TOKEN=###################
TWILIO_SIP_DOMAIN=@@@@@@@@.sip.twilio.com
TWILIO_SIP_USERNAME=@@@@@@@
TWILIO_SIP_PASSWORD=@@@@@@@@@@@@
# This leaves the dial-in/out number list empty for now
TWILIO_PHONE_NUMBERS={}
TWILIO_CHAT_FRIENDLY_NAME=@@@@@@@@
TWILIO_CHAT_SERVICE_SID=IS##########################
TWILIO_SYNC_SERVICE_SID=IS##########################
TWILIO_SYNC_FRIENDLY_NAME=@@@@@@@@
TWILIO_API_FRIENDLY_NAME=@@@@@@@@@
TWILIO_API_SID=SK##############################
TWILIO_API_SECRET=##############################

# Amazon web service details
AWS_RECORDING_BUCKET=@@@@@@@@@@
AWS_STORAGE_BUCKET_NAME=@@@@@@@@@@
AWS_API_KEY=@@@@@@@@@@@@@@@@@@@@
AWS_SECRET=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
AWS_REGION_CODE=us-east-1
AWS_REGION_NAME="US East (N. Virginia)"
# Lifetime in seconds of a recording link you copy from the nVision portal
RECORDING_URL_EXPIRY=7200

# Server domain, as for ALLOWED_HOSTS
DOMAIN_NAME=beta.dsxml.com
# Name of your server in the UI
BRAND_NAME=Focus (beta)
# Root of the site where the custom pages are hosted
SITE_RESOURCE_ROOT=https://sites.google.com/view/buzzin2view

# Your choice of superuser details for the UI.
# DO NOT MAKE THIS GUESSABLE
SUPERUSERNAME=@@@@@@@@@@
SUPERPASSWORD=@@@@@@@@@@

# From the Temi portal
TEMI_API_KEY=###########

# An arbitrary secret string
DAEMON_SECRET=@@@@@@@@@@@@@@@@

# Your Google project id and region
GOOGLE_PROJECT_ID=##########################
REGION_ID=uk
```

### Twilio phone numbers

Twilio phone numbers are used to support dial in/dial out access to meetings for users who do not have a microphone.
This is an increasingingly rare use case. However, for the time being the SIP capability is required as the mechanism to deliver
real-time voice for Google live transcription is dependent on a voice conference with an incoming SIP call from
the Vonage Video server.

The template shows no phone numbers configured. If you had a single UK number, the setting would look like this:
```
TWILIO_PHONE_NUMBERS={"+44##########": {"country": "UK", "display": "0##########","voicing": "voice='alice' language='en-GB", "text_language": "en"}}
```

- The phone number configuration is a JSON dictionary with an entry for every phone number
that you wish to associate with this server.
You might have several, for instance an 800 number, a geographic number and numbers in other
countries for the convenience of international users joining the meeting.
- The JSON string has to be escaped to conform with the .env file format rules.
- The `display` option of the dictionary is the number as you wish to show it in the UI.
- The other options are to select the language and voice to use in the IVR dialogue setting up calls.
Details are in the Twilio documentation.

Note that Twilio now have Know-Your-Customer requirements for you to satisfy before you can operate a telephone number.

### Standard pages

The following pages are expected to be provided as there are hard-coded links to them in the UI. They may be hosted at any HTTPS endpoint, as determined by your SITE_RESOURCE_ROOT setting, so long as they are publicly accessible. They should have compatible styling with your branding but bear in mind they can be accessed from any meeting which may have its own branding so something fairly generic is appropriate.

- /help/connect
- /help/user_help/`x` where x is a participant status:
  - p help for users in meetings as participant
  - f help for users in meetings as facilitator
  - o help for users in meetings as observer
  - m help for users in meetings as moderators
  - r help for users in meetings as shy participants

- /help/help-old-browser
- /help/help-media-choice
- /help/help-denied-permission
- /privacy/recording-policy
- /privacy/cookie-policy
- /privacy/privacy-policy
- /terms

