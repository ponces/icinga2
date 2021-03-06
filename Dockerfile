# Dockerfile for icinga2 with icingaweb2
# https://github.com/jjethwa/icinga2

FROM debian:buster

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    apache2 \
    ca-certificates \
    curl \
    dnsutils \
    file \
    gnupg \
    libdbd-mysql-perl \
    libdigest-hmac-perl \
    libnet-snmp-perl \
    locales \
    lsb-release \
    bsd-mailx \
    mariadb-client \
    mariadb-server \
    netbase \
    openssh-client \
    openssl \
    php-curl \
    php-ldap \
    php-mysql \
    php-mbstring \
    php-gmp \
    procps \
    pwgen \
    snmp \
    msmtp \
    sudo \
    supervisor \
    unzip \
    wget \
    && apt-get -y --purge remove exim4 exim4-base exim4-config exim4-daemon-light \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN export DEBIAN_FRONTEND=noninteractive \
    && curl -s https://packages.icinga.com/icinga.key | apt-key add - \
    && curl -s https://repos.influxdata.com/influxdb.key | apt-key add - \
    && curl -s https://packages.grafana.com/gpg.key | apt-key add - \
    && echo "deb http://packages.icinga.org/debian icinga-$(lsb_release -cs) main" > /etc/apt/sources.list.d/icinga2.list \
    && echo "deb http://deb.debian.org/debian $(lsb_release -cs)-backports main" > /etc/apt/sources.list.d/$(lsb_release -cs)-backports.list \
    && echo "deb https://repos.influxdata.com/debian buster stable" > /etc/apt/sources.list.d/influxdb.list \
    && echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list \
    && apt-get update \
    && apt-get install -y --install-recommends \
    grafana \
    icinga2 \
    icinga2-ido-mysql \
    icingacli \
    icingaweb2 \
    icingaweb2-module-doc \
    icingaweb2-module-monitoring \
    influxdb \
    monitoring-plugins \
    nagios-nrpe-plugin \
    nagios-plugins-contrib \
    nagios-snmp-plugins \
    libmonitoring-plugin-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/share/icingaweb2/modules/ \
    # Icinga Director
    && mkdir -p /usr/local/share/icingaweb2/modules/director/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-director/archive/v1.7.2.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/director --exclude=.gitignore -f - \
    # Icingaweb2 Grafana
    && mkdir -p /usr/local/share/icingaweb2/modules/grafana \
    && wget -q --no-cookies -O - "https://github.com/Mikesch-mp/icingaweb2-module-grafana/archive/v1.3.6.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/grafana -f - \
    # Icingaweb2 AWS
    && mkdir -p /usr/local/share/icingaweb2/modules/aws \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-aws/archive/v1.0.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/aws -f - \
    && wget -q --no-cookies "https://github.com/aws/aws-sdk-php/releases/download/2.8.30/aws.zip" \
    && unzip -d /usr/local/share/icingaweb2/modules/aws/library/vendor/aws aws.zip \
    && rm aws.zip \
    # Icingaweb2 Cube
    && mkdir -p /usr/local/share/icingaweb2/modules/cube \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-cube/archive/v1.1.1.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/cube -f - \
    # Module Reactbundle
    && mkdir -p /usr/local/share/icingaweb2/modules/reactbundle/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-reactbundle/archive/v0.8.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/reactbundle -f - \
    # Module Incubator
    && mkdir -p /usr/local/share/icingaweb2/modules/incubator/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-incubator/archive/v0.5.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/incubator -f - \
    # Module Ipl
    && mkdir -p /usr/local/share/icingaweb2/modules/ipl/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-ipl/archive/v0.5.0.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/ipl -f - \
    # Module x509
    && mkdir -p /usr/local/share/icingaweb2/modules/x509/ \
    && wget -q --no-cookies "https://github.com/Icinga/icingaweb2-module-x509/archive/v1.0.0.zip" \
    && unzip -d /usr/local/share/icingaweb2/modules/x509 v1.0.0.zip \
    && mv /usr/local/share/icingaweb2/modules/x509/icingaweb2-module-x509-1.0.0/* /usr/local/share/icingaweb2/modules/x509/ \
    && rm -rf /usr/local/share/icingaweb2/modules/x509/icingaweb2-module-x509-1.0.0/ \
    && true

ADD content/ /

# Final fixes
RUN true \
    && sed -i 's/vars\.os.*/vars.os = "Docker"/' /etc/icinga2/conf.d/hosts.conf \
    && mv /etc/icingaweb2/ /etc/icingaweb2.dist \
    && mv /etc/icinga2/ /etc/icinga2.dist \
    && mkdir -p /etc/icinga2 \
    && usermod -aG icingaweb2 www-data \
    && usermod -aG nagios www-data \
    && mkdir -p /var/log/icinga2 \
    && chmod 755 /var/log/icinga2 \
    && chown nagios:adm /var/log/icinga2 \
    && rm -rf \
    /var/lib/mysql/* \
    && chmod u+s,g+s \
    /bin/ping \
    /bin/ping6 \
    /usr/lib/nagios/plugins/check_icmp

EXPOSE 80 443 3000 5665

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
