FROM golang:1.16.3-buster AS build

WORKDIR /src/

RUN apt update
RUN apt-get install -y git
RUN git clone https://github.com/FiloSottile/mkcert && \
    cd mkcert &&  \
    go build -ldflags "-X main.Version=$(git describe --tags)" && \
    ./mkcert -install && \
    ./mkcert 127.0.0.1

RUN mv mkcert/127.0.0.1-key.pem 127.0.0.1-key.pem
RUN mv mkcert/127.0.0.1.pem 127.0.0.1.pem

FROM mcr.microsoft.com/azure-storage/azurite

COPY --from=build /src/127.0.0.1.pem /opt/azurite/127.0.0.1.pem
COPY --from=build /src/127.0.0.1-key.pem /opt/azurite/127.0.0.1-key.pem

CMD ["azurite", "-l", "/data", "--blobHost", "0.0.0.0", "--queueHost", "0.0.0.0", "--oauth", "basic", "--cert", "./127.0.0.1.pem", "--key", "./127.0.0.1-key.pem"]