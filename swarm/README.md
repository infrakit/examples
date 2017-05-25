# InfraKit + Docker Swarm Mode

This example bootstraps a Docker swarm running with InfraKit for infrastructure
monitoring and orchestration.

## AWS using CloudFormation

To bootstrap a Docker swarm on AWS using CloudFormation, use the CloudFormation
template found in [aws/vpc.cfn](aws/vpc.cfn).

## AWS using the InfraKit resource plugin

To bootstrap a Docker swarm on AWS using the InfraKit resource plugin, use the InfraKit
resource plugin template found in [aws/vpn.ikt](aws/vpn.ikt).

```sh
docker run -d -v $HOME/.infrakit:/infrakit infrakit/aws:latest instance --region us-west-2 --access-key-id=... --secret-access-key=...

docker run -d -v $HOME/.infrakit:/infrakit infrakit/devbundle:latest infrakit-resource

docker run --rm -v $HOME/.infrakit:/infrakit infrakit/devbundle:latest infrakit resource commit \
    https://infrakit.github.io/examples/swarm/aws/vpc.ikt \
    --global /ec2/keyName=...
```
