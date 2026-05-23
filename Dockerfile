#
# STAGE 1
#
# Uses a Go image to build a release binary.
#
FROM golang:1.26-alpine as builder
ARG tag=latest
ARG INCLUDE_PLUGINS=true
ENV DOCKER_TAG=$tag
ENV GOPATH=/go

WORKDIR /go/src/github.com/alpacahq/marketstore/
ADD ./ ./

RUN apk update
RUN apk --no-cache add git make tar curl alpine-sdk
#RUN  go get -u github.com/golang/dep/... && mv /go/
RUN if [ "$INCLUDE_PLUGINS" = "true" ] ; then make build plugins ; else make build ; fi

#
# STAGE 2
#
# Create final image
#
FROM alpine:3.23
WORKDIR /

RUN apk update && \
    apk --no-cache add ca-certificates tar curl

COPY --from=builder /go/src/github.com/alpacahq/marketstore/marketstore /bin/
COPY --from=builder /go/bin /bin/
COPY --from=builder /go/src/github.com/alpacahq/marketstore/contrib/polygon/polygon-backfill-*.sh /bin/
COPY --from=builder /go/src/github.com/alpacahq/marketstore/contrib/ice/ca-sync-*.sh /bin/

ENV GOPATH=/

RUN ["marketstore", "init"]
RUN mv mkts.yml /etc/
VOLUME /data
EXPOSE 5993

ENTRYPOINT ["marketstore"]
CMD ["start", "--config", "/etc/mkts.yml"]
