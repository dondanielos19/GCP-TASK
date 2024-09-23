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
At the beginning you need install on your local system Kubernetes ( https://kubernetes.io/releases/download/ ) and Terraform ( https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) next you must be logging in Google Cloud Platform and install Google Cloud SDK ( https://cloud.google.com/sdk/docs/install )


When u do prerequisites next use in terminal this command: ```gcloud init``` and logging to GCP, if necessary u can next use this command to logging: ```gcloud auth login```. Next create new project in GCP, command: ``` gcloud projects create my-task-1234 --name="task" ```( my-task-1234 and "task" these are my variables !!!). When u created project check if you have a billing account assigned to it, use command:``` gcloud beta billing projects describe my-task-1234 ```, if in output you dont had billing account you can add it like this command:``` gcloud beta billing projects link my-task-1234 --billing-account YOUR_BILLING_ACCOUNT_ID ```  (also u can check YOUR_BILLING_ACCOUNT_ID this command:``` gcloud beta billing accounts list ```)

Next create simple app and docker file in your work file (e.g. look my files in repository)

Next step is create file Terraform infrastructure called main.tf ( look files in repository )terraform.tfvars and variables.tf to corect work. Before you start Terraform initialization, open main.tf find resource "null_resource" "docker_build_and_push" and set path to your dockerfile. Change the variable in terraform.tfvars to your own project_id, after that you will need to fill the variables.tf file with your data (project_id, git repository, path git repository, domain).

Now u need create git repository with deployment and service your app ( look here https://github.com/dondanielos19/task-gcp-agroCD/tree/master/hello-world-flask/manifests ) and set in deployment your image. On line 129 in main.tf you have a link to the image that will be created, replace it with the variable name of the project and add it to your deployment. Go to variables.tf find resource and fill url git repository and path.

Now u can use command: ```terraform init``` and ```terraform apply```. 

Now it's time to set ur DNS in site your domain operator. Use this command:``` gcloud dns record-sets list --zone=sikalafa-zone --name=sikalafa.pl --type=NS  ```(name is your domain name), outputs are google NS records. In panel your domain operator you must change operator rekords to your google NS records. Now u can managed records from using google Cloud DNS and your ssl/tls certificates should start working but don't forget about waiting for finish propagation (use this side to check propagation status https://www.whatsmydns.net/ ). 
Annotation: in some cases you need to confirm domain ownership on the website: https://search.google.com/search-console/welcome )

If you set DNS and propagation is finish, app should available from https because ingress and certificates configuration is in main.tf.

Now you can configure Prometheus to collect metrics from the application service. Get your ip from hello-world-flask services using this command: kubectl get services

Add your IP in this config:
scrape_configs:
- job_name: FlaskAPP
static_configs:
- targets: YOUR-IP

and add this config job to configmap:``` kubectl edit configmap prometheus-server -n monitoring ```  after  ``` kubectl rollout restart deployment prometheus-server -n monitoring ```,next take ip to open Prometheus in localhost: ``` kubectl port-forward services/prometheus-server -n monitoring  9090:80 ``` and open Prometheus in web browser.
In Prometheus set the metrics you need. Below is a list of popular metrics.
1. App metrics :
http_requests_total – total number of HTTP requests.
http_requests_errors_total – number of HTTP errors (e.g., 4xx, 5xx).
http_request_duration_seconds – duration of HTTP requests (in seconds).
database_query_duration_seconds – time spent on database queries.
application_errors_total – number of application-level errors (e.g., exceptions, business logic issues).
2. Kubernetes infrastructure metrics provided by kube-state-metrics:
container_cpu_usage_seconds_total – CPU usage by containers (in CPU seconds).
container_memory_usage_bytes – memory usage by containers (in bytes).
kube_pod_container_status_restarts_total – number of container restarts within a pod.
kube_pod_status_phase – current status of the pod (Running, Pending, Succeeded, Failed).
container_memory_working_set_bytes – amount of memory actively used by the container (important for detecting OOM issues).
3. Network Metrics
These metrics track network traffic within the cluster:
container_network_receive_bytes_total – amount of data received by the container (in bytes).
container_network_transmit_bytes_total – amount of data sent by the container (in bytes).
container_network_receive_errors_total – number of errors while receiving data in the container.
container_network_transmit_errors_total – number of errors while transmitting data from the container.
kube_pod_container_status_last_terminated_reason – reason for the last termination of a container (e.g., OOM, network failure).
4. Disk Metrics
These metrics are especially important for applications that perform intensive disk I/O operations:
container_fs_reads_bytes_total – number of bytes read from disk by the container.
container_fs_writes_bytes_total – number of bytes written to disk by the container.
container_fs_usage_bytes – amount of disk space used by the container.
container_fs_io_time_seconds_total – time spent on disk I/O operations by the container (in seconds).
container_fs_limit_bytes – disk space limit allocated to the container (in bytes).
5. Prometheus Metrics (Prometheus Health)
Metrics that monitor the health and performance of Prometheus itself:
prometheus_tsdb_head_series – number of active time series stored in the Prometheus TSDB (Time Series Database).
prometheus_target_interval_length_seconds – duration of the scrape interval for targets.
prometheus_target_scrape_pool_reloads_total – number of times the scrape pool has been reloaded.
prometheus_notifications_errors_total – total number of errors encountered while sending notifications (via Alertmanager).
prometheus_http_requests_total – total number of HTTP requests handled by the Prometheus server.

Open Grafana same like Prometheus: ``` kubectl port-forward -n monitoring svc/grafana 3000:80 ```  username: admin password: from terrminal -> ``` kubectl get secret grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d ```
Logging -> Dashboards -> New -> Add visualization -> Configure a new data source -> Prometheus -> add ip prometheus-server  (kubectl get service -n monitoring) -> Save -> Create dashboard using prometheus select metrics and safe it.
Use same configuration to create Kubernetes infrastructure metrics dashboards.


