TAG := 0.5
NAMESPACE := infrakit
UPGRADE_IMAGE := ${NAMESPACE}/upgrade:${TAG}

build:
	docker image build -t infrakit-test -f test/Dockerfile .
	docker image build -t ${UPGRADE_IMAGE} -f Dockerfile .

test: clean build
	docker volume create infrakit 
	docker container run -d -t --name infrakit-test -v infrakit:/infrakit infrakit-test
	docker container run -d --name infrakit-upgrade -v infrakit:/infrakit ${UPGRADE_IMAGE} sh -c "sleep 10 && cp -R /src/* /infrakit"
	docker exec -t infrakit-test watch -d cat /infrakit/swarm/infrakit.sh

clean:
	-docker container rm -f infrakit-test
	-docker container rm -f infrakit-upgrade
	-docker volume rm infrakit