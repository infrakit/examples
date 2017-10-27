Create a new google stack with the command
```
gcloud deployment-manager deployments create <deployment name> --config
cloud-deployment.yaml
```

Make sure the following APIs are enabled!
* (Cloud Deployment Manager)[https://console.developers.google.com/apis/library/deploymentmanager.googleapis.com/]
* (Compute Engine)[https://console.developers.google.com/apis/library/compute.googleapis.com/]
* (IAM)[https://console.developers.google.com/apis/library/iam.googleapis.com/]
