# icinga2

This repository contains the source for the [icinga2](https://www.icinga.org/icinga2/) [docker](https://www.docker.com) image.

## Image details

1. Based on debian:buster
1. Key-Features:
   - icinga2
   - icingacli
   - icingaweb2
   - icingaweb2-director module
   - icingaweb2-module-aws
   - ssmtp
   - MySQL
   - Supervisor
   - Apache2
   - SSL Support
   - Custom CA support
1. No SSH. Use docker [exec](https://docs.docker.com/engine/reference/commandline/exec/) or [nsenter](https://github.com/jpetazzo/nsenter)
1. If passwords are not supplied, they will be randomly generated and shown via stdout.

## Usage

Start a new container and bind to host's port 80

    docker run -p 80:80 -h icinga2 -t ponces/icinga2:latest

## Icinga Web 2

Icinga Web 2 can be accessed at [http://localhost/icingaweb2](http://localhost/icingaweb2) with the credentials *icinga*:*icinga* (if not set differently via variables).  When using a volume for /etc/icingaweb2, make sure to set ICINGAWEB2_ADMIN_USER and ICINGAWEB2_ADMIN_PASS

### Saving PHP Sessions

If you want to save your php-sessions over multiple boots, mount `/var/lib/php/sessions/` into your container. Session files will get saved there.

example:
```
docker run [...] -v $PWD/icingaweb2-sessions:/var/lib/php/sessions/ ponces/icinga2
```

## Icinga Director

The [Icinga Director](https://github.com/Icinga/icingaweb2-module-director) Icinga Web 2 module is installed and enabled by default. You can disable the automatic kickstart when the container starts by setting the `ICINGA2_FEATURE_DIRECTOR_KICKSTART` variable to false. To customize the kickstart settings, modify the `/etc/icingaweb2/modules/director/kickstart.ini`.

## API Master

The container gets automatically configured as an API master. But it has some caveats. Please make sure:

- Set the container's hostname (`-h` or `hostname`)
  - The hostname has to match the name, your sattelites are configured to access the master.
- Forward the `5665` port
- Mount **both** volumes: `/etc/icinga2`, `/var/lib/icinga2`

## Sending Notification Mails

The container has `msmtp` installed, which forwards mails to a preconfigured SMTP server (MTA).

The full documentation for [msmtp is found here](https://marlam.de/msmtp).

You have to edit the file `msmtp/msmtprc` for general configuration and `msmtp/aliases` (mapping from local Unix-user to mail-address). Please note that the example file can be heavily changed and secured, so read the msmtp docs listed above

```
# msmtp/msmtprc
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log
aliases        /etc/aliases

# Gmail
account        gmail
host           smtp.gmail.com
port           587
from           <your-email-address@gmail.com>
user           <your-email-address@gmail.com>
password       <your-password-or-eval-command-to-gpg-file>

# Set a default account
account default: gmail
```

*Note that Gmail has become very restrictive, the preparation and config must be done in Gmail's settings. If you can't get it to work, consider another SMTP service*.

`msmtp/aliases` follows the format: `Unix-user: e-mail-address`.

```
# msmtp/aliases
root:<YOUR_MAILBOX>
default:<YOUR_MAILBOX>
```

As a last config change, edit the `data/icinga/etc/icinga2/conf.d/users.conf` and change the e-mail address `root@localhost` to either `root` or a valid external address. This must be done as msmtp interprets all addresses with an at-sign as external and the transport will fail. If the address is changed to `root` the aliasing feature will use your root alias instead.

These files have to be mounted into the container. Add these flags to your `docker run`-command:

```
-v $(pwd)/msmtp/aliases:/etc/aliases:ro
-v $(pwd)/msmtp/msmtprc:/etc/msmtprc:ro
```

## SSL Support

For enabling of SSL support, just add a volume to `/etc/apache2/ssl`, which contains these files:

- `icinga2.crt`: The certificate file for apache
- `icinga2.key`: The corresponding private key
- `icinga2.chain` (optional): If a certificate chain is needed, add this file. Consult your CA-vendor for additional info.

For https-redirection or http/https dualstack consult `APACHE2_HTTP` env-variable.

## Custom CA Support

In the case where you need to trust a non-default CA, add the certificate(s) as `.crt` files to a volume to be mounted at `/usr/local/share/ca-certificates/`.

Any certificates that are CA certificates with a `.crt` extension in that volume will automatically be added to the CA store at startup.

# Adding own modules

To use your own modules, you're able to install these into `enabledModules`-folder of your `/etc/icingaweb2` volume.

# Reference

## Environment variables Reference

| Environmental Variable | Default Value | Description |
| ---------------------- | ------------- | ----------- |
| `ICINGA2_FEATURE_DIRECTOR` | true | Set to false or 0 to disable icingaweb2 director |
| `ICINGA2_FEATURE_DIRECTOR_USER` | icinga | Icinga2director Login User |
| `ICINGA2_FEATURE_DIRECTOR_PASS` | *random generated each start* | Icinga2director Login Password<br>*Set this to prevent continues [admin] modify apiuser "icinga" activities* |
| `ICINGA2_FEATURE_DIRECTOR_KICKSTART` | true | Set to false to disable icingaweb2 director's auto kickstart at container startup. *Value is only used, if icingaweb2 director is enabled.* |
| `ICINGAWEB2_ADMIN_USER` | icinga | Icingaweb2 Login User<br>*After changing the username, you should also remove the old User in icingaweb2-> Configuration-> Authentication-> Users* |
| `ICINGAWEB2_ADMIN_PASS` | icinga | Icingaweb2 Login Password |
| `ICINGA2_USER_FULLNAME` | Icinga | Sender's display-name for notification e-Mails |
| `GRAFANA_ADMIN_USER` | icinga | Grafana Login User |
| `GRAFANA_ADMIN_PASS` | icinga | Grafana Login Password |
| `CMF_SERVICES_USER` | cmf | CMF Services Global User |
| `CMF_SERVICES_PASS` | cmf | CMF Services Global Password |
| `APACHE2_HTTP` | `REDIRECT` | **Variable is only active, if both SSL-certificate and SSL-key are in place.** `BOTH`: Allow HTTP and https connections simultaneously. `REDIRECT`: Rewrite HTTP-requests to HTTPS |
| `MYSQL_ROOT_USER` | root | If your MySQL host is not on `localhost`, but you want the icinga2 container to setup the DBs for itself, specify the root user of your MySQL server in this variable. |
| `MYSQL_ROOT_PASSWORD` | *unset* | If your MySQL host is not on `localhost`, but you want the icinga2 container to setup the DBs for itself, specify the root password of your MySQL server in this variable. |
| `TZ` | UTC | Specify the TimeZone for the container to use|

## Volume Reference

All these folders are configured and able to get mounted as volume. The bottom ones are not quite necessary.

| Volume | ro/rw | Description & Usage |
| ------ | ----- | ------------------- |
| /etc/apache2/ssl | **ro** | Mount optional SSL-Certificates (see SSL Support) |
| /etc/locale.gen | **ro** | In format of the well known locale.gen file. All locales listed in this file will get generated. |
| /etc/ssmtp/revaliases | **ro** | revaliases map (see Sending Notification Mails) |
| /etc/ssmtp/ssmtp.conf | **ro** | ssmtp configuration (see Sending Notification Mails) |
| /etc/icinga2 | rw | Icinga2 configuration folder |
| /etc/icingaweb2 | rw | Icingaweb2 configuration folder |
| /var/lib/mysql | rw | MySQL Database |
| /var/lib/icinga2 | rw | Icinga2 Data |
| /var/lib/php/sessions/ | rw | Icingaweb2 PHP Session Files |
| /var/log/apache2 | rw | logfolder for apache2 (not neccessary) |
| /var/log/icinga2 | rw | logfolder for icinga2 (not neccessary) |
| /var/log/icingaweb2 | rw | logfolder for icingaweb2 (not neccessary) |
| /var/log/mysql | rw | logfolder for mysql (not neccessary) |
| /var/log/supervisor | rw | logfolder for supervisord (not neccessary) |
| /var/spool/icinga2 | rw | spool-folder for icinga2 (not neccessary) |
| /var/cache/icinga2 | rw | cache-folder for icinga2 (not neccessary) |
