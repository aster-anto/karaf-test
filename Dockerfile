# Pull base image.
FROM ubuntu

MAINTAINER ypk

ARG USER_HOME_DIR="/root"
ARG KARAF_HOME="/opt/karaf"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y \
    apt-utils \
    git-core \
    build-essential \
    gperf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install supporting libs
RUN apt-get -y update \
    && apt-get install -y \
    curl \
    python-software-properties \
    software-properties-common \
    sshpass

# Install Java.
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

RUN apt-get install -y oracle-java8-set-default

# Define working directory.
WORKDIR /home

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Install Maven

RUN apt-get update \
  && apt-get install -y \
  maven \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Define commonly used MAVEN_HOME variable
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"


ENV KARAF_VERSION=4.1.1

RUN wget http://www-us.apache.org/dist/karaf/${KARAF_VERSION}/apache-karaf-${KARAF_VERSION}.tar.gz; \
  mkdir /opt/karaf; \
  tar --strip-components=1 -C /opt/karaf -xzf apache-karaf-${KARAF_VERSION}.tar.gz; \
  rm apache-karaf-${KARAF_VERSION}.tar.gz; \
  mkdir /deploy; \
  sed -i 's/^\(felix\.fileinstall\.dir\s*=\s*\).*$/\1\/deploy/' /opt/karaf/etc/org.apache.felix.fileinstall-deploy.cfg

VOLUME ["/deploy"]

#VOLUME ./karaf "$KARAF_HOME/deploy"
VOLUME "$USER_HOME_DIR/.m2"

#COPY ./karaf/* "$KARAF_HOME/deploy/"
ENV PATH $PATH:$JAVA_HOME/bin
RUN java -version
RUN echo $JAVA_HOME
RUN which java
RUN echo $KARAF_HOME

#RUN $KARAF_HOME/bin/karaf \
#  && echo "feature:install webconsole" \
#  "feature:install wss-osgi-dependencies" \
#  "feature:install wss-osgi-jackson" \
#  "feature:install wss-osgi-email-dependencies" \
#  "feature:install wss-osgi-cxf" \
#  "feature:install wss-osgi-drools" \
#  && $KARAF_HOME/bin/stop

EXPOSE 1099 8101 44444
#RUN echo '#!/bin/bash\nsshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost' > /usr/bin/karaf_client
#RUN chmod +x /usr/bin/karaf_client
#RUN /opt/karaf/bin/start clean; until sshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost version; do sleep 5s; done; /opt/karaf/bin/stop;

RUN $KARAF_HOME/bin/start; \
    until sshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost version; do sleep 5s; done; \
    sshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost feature:install webconsole; \
    sshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost feature:install wss-osgi-dependencies; \
    sshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost feature:install wss-osgi-jackson; \
   sshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost feature:install wss-osgi-email-dependencies; \
    sshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost feature:install wss-osgi-cxf; \
    sshpass -p karaf ssh -tt -p 8101 -o StrictHostKeyChecking=no karaf@localhost feature:install wss-osgi-drools; \
    $KARAF_HOME/bin/stop;

EXPOSE 8443 8181 5701 54327
    
# Define default command.
ENTRYPOINT ["/opt/karaf/bin/karaf"]