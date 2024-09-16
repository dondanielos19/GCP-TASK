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


When u do prerequisites next use in terminal this command: gcloud init and logging to GCP, if necessary u can next use this command to logging: gcloud auth login. Next create new project in GCP, command: gcloud projects create my-task-123 --name="task" ( my-task-123 and "task" these are my variables !!!). When u created project check if you have a billing account assigned to it, use command: gcloud beta billing projects describe my-task-123 , if in output you dont had billing account you can add it like this command: gcloud beta billing projects link my-task-123 --billing-account YOUR_BILLING_ACCOUNT_ID  (also u can check YOUR_BILLING_ACCOUNT_ID this command: gcloud beta billing accounts list)

Next create simple app and docker file in your work file (e.g. look my files in repository)

Next step is create file Terraform infrastructure called main.tf ( look files in repository ) and variables.tf to corect work. Before you start Terraform initialization, open main.tf find resource "null_resource" "docker_build_and_push" and set path to your dockerfile. Change the variable in terraform.tfvars to your own project_id, after that you will need to fill the variables.tf file with your data. At first, the "project_id" variable will be enough, and you will fill the other variables later, after you create the infrastructure.

Now u can use command: terraform init and terraform apply. After first apply u get some errors because cluster need time to get on and other resource cant create. Wait about 5min use this command: gcloud container clusters get-credentials primary-cluster --region us-central1 --project my-task-123 (set your region and project_id) to confgure kubeconfig. Use one more time terraform apply now you can see only 1 error like this: 
"Error: failed to create new session client
│ 
│   with argocd_application.hello_world_flask,
│   on main.tf line 230, in resource "argocd_application" "hello_world_flask":
│  230: resource "argocd_application" "hello_world_flask" {
│ 
│ dial tcp: lookup ipagro on 127.0.0.53:53: server misbehaving"

These errors occur because the entire infrastructure is in the main.tf file, which is not created gradually, but all at once. The last Error is related to ArgoCD, it is that we now need to fill in the rest of the variables in variables.tf.
Use command: kubect get services -n argocd  and coppy external ip to variable "argocd_server_addr" next fill variable "argocd_password" taking password from this command: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d   

Now u need create git repository with deployment and service your app ( look here https://github.com/dondanielos19/task-gcp-agroCD/tree/master/hello-world-flask/manifests ) and set in deployment your image. Use this command to find image paht: gcloud artifacts docker images list us-central1-docker.pkg.dev/my-task-123/repo --project=my-task-123 and add tag v1 (e.g. us-central1-docker.pkg.dev/my-task-123/repo/hello-world-flask:v1 ). Go to main.tf find resource "argocd_application" "hello_world_flask" and fill url git repository and path. Use terraform apply, now you shouldn't have any errors. ArgoCD now deploy deployment and service. You can also loggin to UI AgroCD using external ip and username: admin and your password.

Dopisać o ustawieniu zmiennej domeny na swoja!!!   Now it's time to set ur DNS in site your domain operator. Use this command: gcloud dns record-sets list --zone=sikalafa-zone --name=sikalafa.pl --type=NS  (name is your domain name), outputs are google NS records. In panel your domain operator you must change operator rekords to your google NS records. Now u can managed records from using google Cloud DNS and your ssl/tls certificates should start working but don't forget about waiting for finish propagation (use this side to check propagation status https://www.whatsmydns.net/ ). 




