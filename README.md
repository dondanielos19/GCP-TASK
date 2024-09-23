# GCP-TASK
# TASK 
Follow the below steps, all infrastructure should be created by Terraform
1. Create kubernetes cluster in google cloud platform (GKE)
2. Create simple app (e.g. in python), create manifests and dockerfile
3. Deploy ArgoCD on the cluster, your app must be deployed and updated by ArgoCD
4. App should be avaible from https, so you need add certificate ssl/tls
5. Deploy Prometheus on the cluster and configure it to collect metrics
6. Deploy Grafana on the cluster and create dashboard based on these metrics
    
# Execution of the task
prerequisites: 
At the beginning you need install on your local system:
1. Kubernetes ( https://kubernetes.io/releases/download/ )
2. Terraform ( https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
3. Google Cloud SDK ( https://cloud.google.com/sdk/docs/install )


When u do prerequisites, use in terminal this commands: 
```
gcloud init  #initialization gcloud
```
```
gcloud auth login``` #login to gcp
```
```
gcloud projects create my-task-1234 --name="task" #creating new project ( my-task-1234 and "task" these are my variables !!!)
```

Create folder call "gcp" and put the files from this repository in it.
Open infrastructure folder and set your variables in terraform.tfvars and variables.tf. 
Next use this command: 
```
terraform init 
```
```
terraform apply
```
Now you create all necessary resources for infrastructure from infrastructure.tf file. 

Google Cloud DNS setup
Use this command:
``` 
gcloud dns record-sets list --zone= YOUR ZONE --name= DOMAIN NAME --type=NS
```
In panel your domain operator you must change operator rekords to your google NS records.(use this side to check propagation status https://www.whatsmydns.net/ ). 
Annotation: in some cases you need to confirm domain ownership on the website: https://search.google.com/search-console/welcome )

Create git repository with deployment and service like mine https://github.com/dondanielos19/task-gcp-agroCD/tree/master/hello-world-flask/manifests ) in deployment set your image from Artifact Registry. 

Open folder cluster_operations fill variables in variables.tf.Use commmands: 
```
terraform init
```
```
terraform apply
```
Now your cluster is being configured

To monitor your application open prometheus

```
kubectl port-forward services/prometheus-server -n monitoring  9090:80 
``` 
Sample useful queries for application metrics:
1. http_requests_total – total number of HTTP requests
2. http_requests_errors_total – number of HTTP errors (e.g., 4xx, 5xx)
3. http_request_duration_seconds – duration of HTTP requests (in seconds)


Open Grafana same like Prometheus:

```
kubectl port-forward -n monitoring svc/grafana 3000:80
```

username: admin
password: from terrminal ->
```
kubectl get secret grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
```

Steps to create Dashboards:
Loging -> Dashboards -> New -> Add visualization -> Configure a new data source -> Prometheus -> add ip prometheus-server -> Save -> Create dashboard using prometheus select metrics and safe it.


