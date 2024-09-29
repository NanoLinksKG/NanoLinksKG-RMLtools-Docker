FROM ubuntu:22.04

LABEL maintainer "Ammar Ammar <ammar257ammar@gmail.com>"

RUN apt update && \
	apt install -y openjdk-8-jdk openjdk-8-jre-headless ant maven git && \
	apt install -y wget curl dirmngr apt-transport-https lsb-release ca-certificates-java && \
	curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
	apt update && \
	apt install -y nodejs && \
	apt clean && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/cache/oracle-jdk8-installer

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

RUN npm i -g @rmlio/yarrrml-parser

WORKDIR /app

RUN wget https://github.com/NanoLinksKG/rmlmapper-java/releases/download/v4.15.0/rmlmapper-4.15.0-r361-all.jar -O rmlmapper.jar

RUN git clone https://github.com/NanoLinksKG/NanoLinksKG-rmlmapper-functions.git && \
	cd NanoLinksKG-rmlmapper-functions && \
	mvn package && \
	mv target/nanolinks-rmlmapper-functions-1.0-Stable.jar /app/rmlmapper-functions-1.0-Stable.jar && \
	cd .. && \
	rm -rf NanoLinksKG-rmlmapper-functions
	
COPY functions.ttl /app/functions.ttl
COPY entrypoint.sh /app/entrypoint.sh
COPY gene-exp-mapping.sh /app/gene-exp-mapping.sh

RUN chmod 775 /app/gene-exp-mapping.sh

ENTRYPOINT ["/app/entrypoint.sh"]