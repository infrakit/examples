FROM alpine:3.6
MAINTAINER FrenchBen <FrenchBen@docker.com>
COPY latest /src/
WORKDIR /infrakit
VOLUME ["/infrakit"]

CMD ["cp", "-R", "/src/*", "/infrakit"]
