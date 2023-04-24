FROM golang:1.20-bullseye AS builder

WORKDIR /usr/local/src/ddbimp
ADD . .
ENV GOPROXY=direct
RUN go build -o /opt/ddbimp .


FROM ubuntu:lunar

SHELL ["/bin/bash", "-c"]
ENV BIN_PATH=/usr/local/bin/

WORKDIR $BIN_PATH
RUN apt update -y > /dev/null && apt install -y awscli
COPY --from=builder /opt/ddbimp $BIN_PATH
RUN chmod +x $BIN_PATH/ddbimp

WORKDIR /var/ddbimp

ENTRYPOINT ["tail", "-f", "/dev/null"]
