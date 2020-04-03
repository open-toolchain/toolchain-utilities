FROM openwhisk/dockerskeleton

ENV FLASK_PROXY_PORT 8080

LABEL maintainer="Benoit Jaunin <jaunin.b@fr.ibm.com>"

RUN apk update && apk upgrade

RUN apk --no-cache add jq curl

WORKDIR /root

ENV HOME /root

RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

#dev plugin is already installed
#RUN ibmcloud plugin install dev

WORKDIR /

ADD pipeline-run.sh /action/exec
RUN chmod +x /action/exec