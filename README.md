# Deploy Applications to Azure Kubernetes Service (AKS)

> **Note**: Throughout this course I use the `k` alias as a shorthand for `kubectl`, you can set the `k` alias using the following command:

```bash
alias k=kubectl
```

## Module 1: Preparing for Application Deployment

### Application Deployment Concepts

- No additional resources.

### Attach an Azure Container Registry

#### Resources

- In the Cloud Playground Sandbox, you can use [Image Pull Secret](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes) as an alternative to using an attached Container Registry.

#### Code Snippets

- (Sample) Set variables used for the sample commands:

    ```bash
    RG=rg-create-an-azure-container-registry
    ACR=cr$RANDOM
    SKU=basic
    ```

- (Sample) Create an Azure Container Registry:

    ```bash
    az acr create \
    --name $ACR \
    --resource-group $RG \
    --sku $SKU
    ```

- (Sample) Create an AKS cluster with an attached Container Registry:

    ```bash
    az aks create \
    --name NewCluster \
    --resource-group $RG \
    --attach-acr $ACR \
    --generate-ssh-keys
    ```

- (Sample) Attach a Container Registry to an existing AKS Cluster:

    ```bash
    az aks update \
    --name ExistingCluster \
    --resource-group $RG \
    --attach-acr $ACR
    ```

- (Sample) Validate an attached Container Registry:

    ```bash
    az aks check-acr \
    --name ExistingCluster \
    --resource-group $RG \
    --acr $ACR
    ```

### Build and Push Container Images

#### Resources

- [Sample GitHub Actions Workflow](.github/workflows/BuildandPushContainerImage.yml)
- [Sample application with Dockerfile](AKSWebApp)

#### Code Snippets

- (Sample) Set variables used for the sample commands:

    ```bash
    RG=rg-build-and-push-container-images
    ACR=$(az acr list --resource-group $RG --query [].name --output tsv)
    ```

- (Sample) Log in to an Azure Container Registry (ACR):

    ```bash
    az acr login --name $ACR
    ```

- (Sample) Clone a Git repository:

    ```bash
    git clone https://github.com/pluralsight-cloud/aks-deploy-applications
    ```

- (Sample) Build a container image using Docker:

    ```bash
    docker build --tag akswebapp:v1 .
    ```

- (Sample) Tag an image so it can be pushed to an Azure Container Registry (ACR):

    ```bash
    ACR_LOGIN_SERVER=$(az acr show --name $ACR --query loginServer --output tsv)
    docker tag akswebapp:v1 $ACR_LOGIN_SERVER/akswebapp:v1
    ```
- List images with Docker:

    ```bash
    docker image list
    ```

- (Sample) Push a container image to Azure Container Registry (ACR) using Docker:

    ```bash
    ACR_LOGIN_SERVER=$(az acr show --name $ACR --query loginServer --output tsv)
    docker push $ACR_LOGIN_SERVER/akswebapp:v1
    ```

- Build a container image using a quick task in Azure Container Registry (ACR):

    ```bash
    az acr build --registry $ACR --image akswebapp:v1 .
    ```

## Module 2: Deploying Applications

### Customizing Applications for Deployment

- No additional resources.

### Demo: Deploy Applications Manually

#### Resources

- [Sample Manifests](Manifests)

#### Code Snippets

- Code Snippet to set commonly used variables and the `k` alias:

    ```bash
    RG=rg-deploy-applications-manually
    AKS=$(az aks list --resource-group $RG --query [].name --output tsv)
    ACR=$(az acr list --resource-group $RG --query [].name --output tsv)
    ACR_LOGIN_SERVER=$(az acr show --name $ACR --query loginServer --output tsv)
    alias k=kubectl
    az aks get-credentials --resource-group $RG --name $AKS
    ```

- Create a namespace and save the config so it can be updated with `k apply`:

    ```bash
    k create namespace akswebapp-prod --save-config
    ```

- (Sample) Generate the YAML for a namespace:

    ```bash
    k create namespace akswebapp-prod --dry-run=client --output yaml > deployment-prod.yaml
    ```

- (Sample) Generate the YAML for a deployment and append it to an existing YAML file:

    ```bash
    k create deployment akswebapp --image=$ACR_LOGIN_SERVER/akswebapp:v1 --namespace akswebapp-prod --replicas=1 --dry-run=client --output yaml >> deployment-prod.yaml
    ```

- (Sample) Generate the YAML for a Load Balancer service and append it to an existing YAML file:

    ```bash
    k create service loadbalancer akswebapp --namespace akswebapp-prod --tcp=80:8080 --dry-run=client --output yaml >> deployment-prod.yaml
    ```

- (Sample) Apply a YAML kubernetes manifest:

    ```bash
    k apply -f deployment-prod.yaml
    ```

- (Sample) List all Kubernetes resources in a namespace:

    ```bash
    k get all --namespace akswebapp-prod
    ```

### Demo: Applying Kustomizations

#### Resources

- [Sample Kustomizations](Kustomize)
- [Install Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)

#### Code Snippets

- Install Kustomize on Ubuntu using Snap:

    ```bash
    sudo snap install kustomize
    ```

- (Sample) Create a Kustomization:

    ```bash
    kustomize create --autodetect --recursive
    ```

- (Sample) Create an overlay and add resources:

    ```bash
    cd overlays/staging
    kustomize create --namespace staging --namesuffix "-staging" --resources '../../base'
    ```

- (Sample) Build a Kustomization:

    ```bash
    kustomize build akswebapp/overlays/staging
    ```

- (Sample) Apply a Kustomization:

    ```bash
    k apply -k akswebapp/overlays/staging
    ```

### Demo: Deploying Applications with Helm

#### Resources

- [Sample Chart](Helm)
- [Install Helm](https://helm.sh/docs/intro/install/)

#### Code Snippets

- Install Helm on Ubuntu using Snap:

    ```bash
    sudo snap install helm --classic
    ```

- (Sample) Create an example Helm Chart:

    ```bash
    helm create AKSWebApp
    ```

- (Sample) Install a Helm Chart, creating a namespace, and setting a value:

    ```bash
    helm install akswebapp-staging ./AKSWebApp --namespace akswebapp-staging --create-namespace --set Environment=Staging
    ```

### Automated Application Deployment Methods

- No additional resources.

### Demo: Deploying Applications with Flux

#### Resources

- [Microsoft Documentation: Deploy applications using GitOps with Flux v2](https://learn.microsoft.com/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2)

#### Code Snippets

- Install the latest `k8s-configuration` and `k8s-extension`.

    ```bash
    az extension add --name k8s-extension
    az extension add --name k8s-configuration
    ```

- (Sample) Create a Flux configuration to enable GitOps on an existing AKS cluster:

    ```bash
    az k8s-configuration flux create \
    --resource-group $RG \
    --cluster-name $AKS \
    --namespace flux \
    --name akswebapp \
    --cluster-type managedClusters \
    --scope cluster \
    --url https://github.com/pluralsight-cloud/aks-deploy-applications/AKSWebApp \
    --branch main  \
    --kustomization name=production path=./Kustomize/akswebapp/overlays/production prune=true \
    --kustomization name=staging path=./Kustomize/akswebapp/overlays/staging prune=true
    ```

     > **Note**: This sample needs to be modified to used.

### Demo: Deploying Applications with Argo CD

#### Resources

- [Argo CD - Installation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
- [Argo CD - Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Access The Argo CD API Server](https://argo-cd.readthedocs.io/en/stable/getting_started/#3-access-the-argo-cd-api-server)

#### Code Snippets

- Install Argo CD on Linux:

    ```bash
    VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    ```

- Install Argo CD in your Kubernetes Cluster:

    ```bash
    alias k=kubectl
    k create namespace argocd
    k apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

- Patch the service to update it to be of type Load Balancer:

    ```bash
    k patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    ```

- Retrieve the initial Argo CD admin password:

    ```bash
    argocd admin initial-password -n argocd
    ```

- (Sample) Deploy an application to your AKS Cluster using Argo CD:

    ```bash
    argocd app create akswebapp-staging \
    --repo https://github.com/pluralsight-cloud/aks-deploy-applications/AKSWebApp \
    --path Helm/AKSWebApp \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace staging \
    --helm-set-string Environment=Staging \
    --sync-option CreateNamespace=true
    ```

    ```bash
    argocd app set akswebapp-prod --sync-policy automated
    ```

    > **Note**: This sample needs to be modified to use your GitHub repository and the manifests must be updated to use your container registry and image.

- (Sample) Enable auto-sync:

    ```bash
    argocd app set akswebapp-prod --sync-policy automated
    ```

## Module 3: Integrating with Azure Services

### Kubernetes Storage Concepts

### Demo: Use Azure Files with AKS

### AKS Identity Concepts

### Demo: Configure Workload Identity Federation with AKS

### Demo: Use Azure Key Vault with AKS
