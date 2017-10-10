# InfraKit + Docker Swarm Mode + Kubernetes


This example uses AWS Cloudformation to bootstrap a Docker Swarm running with Infrakit for infrastructure
monitoring and orchestration.  This is a self-bootstrapping cluster where every node in the cluster is
either a control plane memeber (a kube master) or a data plane member (worker).

Note the use of a combo plugin where we combine installation of a Docker swarm and then on top of it
we install the kubernetes cluster.  There are 3 swarm manager nodes / infrakit for HA and the first
node is also the kubernetes master.  Currently only a single master kube cluster is implemented.
We will add HA of the kube masters too in the near future.

To test it out, use the CFN script found in [aws/vpc.cfn](aws/vpc.cfn).
