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

prerequisites: czy Docker też?
at the beginning you need install on your local system Kubernetes ( https://kubernetes.io/releases/download/ ) and Terraform ( https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) next you must be logging in Google Cloud Platform and install Google Cloud SDK ( https://cloud.google.com/sdk/docs/install )


When u do prerequisites next use in terminal this commend: gcloud init and logging to GCP, if necessary u can next use this commend to logging: gcloud auth login. Next create new project in GCP, commend: gcloud projects create my-task-123 --name="task" ( my-task-123 and "task" these are my variables !!!). When u created project check if you have a billing account assigned to it, use commend: gcloud beta billing projects describe my-task-123 , if in output you dont had billing account you can add it like this commend: gcloud beta billing projects link my-task-123 --billing-account YOUR_BILLING_ACCOUNT_ID  (also u can check YOUR_BILLING_ACCOUNT_ID this commend gcloud beta billing accounts list)

Next create simple app and docker file in your work file (e.g. look my files in repository)

Next step is create file Terraform infrastructure called main.tf ( look files in repository ) and variables.tf to corect work. Before you start Terraform initialization, open main.tf find resource "null_resource" "docker_build_and_push" and set path to your dockerfile. Change the variable in terraform.tfvars to your own project_id, after that you will need to fill the variables.tf file with your data. At first, the "project_id" variable will be enough, and you will fill the other variables later, after you create the infrastructure.

Now u can use commend: terraform init and terraform apply. After first apply u get some errors because cluster need time to get on and other resource cant create. Wait about 5min use this commend: gcloud container clusters get-credentials primary-cluster --region us-central1 --project my-task-123 (set your region and project_id) to confgure kubeconfig. Use one more time terraform apply now you can see only 1 error like this: 
"Error: failed to create new session client
│ 
│   with argocd_application.hello_world_flask,
│   on main.tf line 230, in resource "argocd_application" "hello_world_flask":
│  230: resource "argocd_application" "hello_world_flask" {
│ 
│ dial tcp: lookup ipagro on 127.0.0.53:53: server misbehaving"

These errors occur because the entire infrastructure is in the main.tf file, which is not created gradually, but all at once. The last Error is related to ArgoCD, it is that we now need to fill in the rest of the variables in variables.tf. 
 



