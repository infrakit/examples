FROM alpine:3.6
MAINTAINER FrenchBen <FrenchBen@docker.com>
RUN apk add --update --no-cache tini

COPY latest /infratest
COPY test/entry.sh /entry.sh
RUN chmod +x /entry.sh
ENTRYPOINT ["/sbin/tini", "--", "/entry.sh"]

CMD ["top"]