FROM alpine:3.16

RUN apk add --no-cache curl bash 

WORKDIR /opt/apicurio
COPY . /opt/apicurio/

CMD bash ./start.sh