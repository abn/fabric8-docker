FROM centos

# telnet is required by some fabric command. without it you have silent failures
RUN yum install -y java-1.7.0-openjdk which telnet unzip openssh-server \
 sudo openssh-clients util-linux

# enabling sudo group
RUN grep '^%wheel' /etc/sudoers > /dev/null \
 || echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

ENV JAVA_HOME /usr/lib/jvm/jre

# default to latest version of io.fabric8:fabric8-karaf:LATEST
ENV FABRIC8_SRC_DEFAULT https://repository.sonatype.org/service/local/artifact/maven/redirect?r=central-proxy&g=io.fabric8&a=fabric8-karaf&v=LATEST&e=zip

# configuration
ENV FABRIC8_KARAF_NAME root
ENV FABRIC8_BINDADDRESS 0.0.0.0
ENV FABRIC8_PROFILES docker
ENV FABRIC8_START_SCRIPT /usr/bin/fabric8-start
ENV FABRIC8_HOME /usr/share/fabric8

# add a user for the application, with sudo permissions
RUN rm -rf $FABRIC8_HOME
RUN useradd -m -d $FABRIC8_HOME fabric8
RUN usermod -s /sbin/nologin -a -G wheel fabric8
WORKDIR /usr/share/fabric8

# command line goodies
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/profile
RUN echo "alias ll='ls -l --color=auto'" >> /etc/profile
RUN echo "alias grep='grep --color=auto'" >> /etc/profile

RUN curl --silent --location --output fabric8.zip \
 ${FABRIC8_SRC:-$FABRIC8_SRC_DEFAULT}
RUN unzip -q fabric8.zip 
RUN rm fabric8.zip
RUN find $(pwd) -maxdepth 1 -type d -name "fabric8-karaf-*" \
 | head -n 1 \
 | xargs -I {} mv {} fabric8-karaf

WORKDIR /usr/share/fabric8/fabric8-karaf/etc

# lets remove the karaf.name by default so we can default it from env vars
RUN sed -i '/karaf.name=root/d' system.properties 

RUN echo bind.address=0.0.0.0 >> system.properties
RUN echo fabric.environment=docker >> system.properties
RUN echo zookeeper.password.encode=true >> system.properties

# lets remove the karaf.delay.console=true to disable the progress bar
RUN sed -i '/karaf.delay.console=true/d' config.properties 
RUN echo karaf.delay.console=false >> config.properties

# lets add a user - should ideally come from env vars?
RUN touch users.properties
RUN sed -i '/^admin=/d' users.properties
RUN sed -i '/developerUserPassword/d' users.properties
RUN TEMP_PASSWORD=${FABRIC8_ADMIN_PASSWORD:-$(strings /dev/urandom \
 | grep -o '[[:alnum:]]' | head -n 8 | tr -d '\n'; echo)}; \
 echo admin=${TEMP_PASSWORD},admin >> users.properties

# lets enable logging to standard out
RUN echo log4j.rootLogger=INFO, stdout, osgi:* >> org.ops4j.pax.logging.cfg 

# ensure we have a log file to tail 
RUN mkdir -p $FABRIC8_HOME/data/log
RUN touch $FABRIC8_HOME/data/log/karaf.log

RUN chown -R fabric8:fabric8 $FABRIC8_HOME

RUN curl --silent --output $FABRIC8_START_SCRIPT \
 https://raw.githubusercontent.com/fabric8io/fabric8-docker/master/startup.sh
RUN chmod +x $FABRIC8_START_SCRIPT

RUN [ ${ENABLE_SSHD:-0} -eq 1 ] && service sshd start || echo Skipping sshd start

EXPOSE 22 1099 2181 8101 8181 9300 9301 44444 61616

USER fabric8
