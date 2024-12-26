#!/usr/bin/env nu

def --env "main apply backstage" [] {

    let kube_url = open kubeconfig-dot.yaml
        | get clusters.0.cluster.server
    $"export KUBE_URL=$(kube_url)\n" | save --append .env

    let kube_ca_data = open kubeconfig-dot.yaml
        | get clusters.0.cluster.certificate-authority-data
    $"export KUBE_CA_DATA=$(kube_ca_data)\n" | save --append .env

    kubectl create namespace backstage

    {
        apiVersion: "v1"
        kind: "ServiceAccount"
        metadata: {
            name: "backstage"
            namespace: "backstage"
        }
    } | to yaml | kubectl apply --filename -

    {
        apiVersion: "v1"
        kind: "Secret"
        metadata: {
            name: "backstage"
            namespace: "backstage"
            annotations: {
                "kubernetes.io/service-account.name": "backstage"
            }
        }
        type: "kubernetes.io/service-account-token"
    } | to yaml | kubectl apply --filename -

    {
        apiVersion: "rbac.authorization.k8s.io/v1"
        kind: "ClusterRoleBinding"
        metadata: {
             name: "backstage"
        }
        subjects: [{
            kind: "ServiceAccount"
            name: "backstage"
            namespace: "backstage"
        }]
        roleRef: {
            kind: "ClusterRole"
            name: "cluster-admin"
            apiGroup: "rbac.authorization.k8s.io"
        }
    } | to yaml | kubectl apply --filename -

    let token = (
            kubectl --namespace backstage get secret backstage
                --output yaml
        ) | from yaml
        | get data.token
        | decode base64
        | decode
    $"export KUBE_SA_TOKEN=$(token)\n" | save --append .env
    
    print $"
When asked for a name for the Backstage app make sure to keep the default value (ansi yellow_bold)backstage(ansi reset)
Press any key to continue.
"
    input

    npx @backstage/create-app@latest

    cd backstage

    for package in [
        "@vrabbi/backstage-plugin-crossplane-common@1.0.1",
        "@vrabbi/backstage-plugin-crossplane-permissions-backend@1.0.1",
        "@vrabbi/backstage-plugin-kubernetes-ingestor@1.0.1",
        "@vrabbi/backstage-plugin-scaffolder-backend-module-terasky-utils@1.0.1"
    ] {
        yarn --cwd packages/backend add $package
    }

    for package in [
        @vrabbi/backstage-plugin-crossplane-resources-frontend@1.0.1
    ] {
        yarn --cwd packages/app add $package
    }

    open app-config.yaml
        | upsert crossplane.enablePermissions false
        | upsert kubernetesIngestor.components.enabled true
        | upsert kubernetesIngestor.components.taskRunner.frequency 10
        | upsert kubernetesIngestor.components.taskRunner.timeout 600
        | upsert kubernetesIngestor.components.excludedNamespaces []
        | upsert kubernetesIngestor.components.excludedNamespaces.0 "kube-public"
        | upsert kubernetesIngestor.components.excludedNamespaces.1 "kube-system"
        | upsert kubernetesIngestor.components.disableDefaultWorkloadTypes true
        | upsert kubernetesIngestor.components.onlyIngestAnnotatedResources false
        | upsert kubernetesIngestor.crossplane.claims.ingestAllClaims true
        | upsert kubernetesIngestor.crossplane.xrds.publishPhase.allowedTargets ["github.com"]
        | upsert kubernetesIngestor.crossplane.xrds.publishPhase.target "github.com"
        | upsert kubernetesIngestor.crossplane.xrds.publishPhase.target "github.com"
        | upsert kubernetesIngestor.crossplane.xrds.publishPhase.allowRepoSelection true
        | upsert kubernetesIngestor.crossplane.xrds.enabled true
        | upsert kubernetesIngestor.crossplane.xrds.taskRunner.frequency 10
        | upsert kubernetesIngestor.crossplane.xrds.taskRunner.timeout 600
        | upsert kubernetesIngestor.crossplane.xrds.ingestAllXRDs true
        | upsert kubernetes {}
        | upsert kubernetes.frontend.podDelete.enabled true
        | upsert kubernetes.serviceLocatorMethod.type "multiTenant"
        | upsert kubernetes.clusterLocatorMethods [{}]
        | upsert kubernetes.clusterLocatorMethods.0.type "config"
        | upsert kubernetes.clusterLocatorMethods.0.clusters [{}]
        | upsert kubernetes.clusterLocatorMethods.0.clusters.0.url "${KUBE_URL}"
        | upsert kubernetes.clusterLocatorMethods.0.clusters.0.name "kind"
        | upsert kubernetes.clusterLocatorMethods.0.clusters.0.authProvider "serviceAccount"
        | upsert kubernetes.clusterLocatorMethods.0.clusters.0.skipTLSVerify true
        | upsert kubernetes.clusterLocatorMethods.0.clusters.0.skipMetricsLookup true
        | upsert kubernetes.clusterLocatorMethods.0.clusters.0.serviceAccountToken "${KUBE_SA_TOKEN}"
        | upsert kubernetes.clusterLocatorMethods.0.clusters.0.caData "${KUBE_CA_DATA}"
        | save app-config.yaml --force

    open packages/app/src/components/catalog/EntityPage.tsx
        | (
            str replace
            `} from '@backstage/plugin-kubernetes';`
            `} from '@backstage/plugin-kubernetes';

import { CrossplaneAllResourcesTable, CrossplaneResourceGraph, isCrossplaneAvailable } from '@vrabbi/backstage-plugin-crossplane-resources-frontend';`
        ) | (
            str replace
            `const serviceEntityPage = (
  <EntityLayout>
    <EntityLayout.Route path="/" title="Overview">
      {overviewContent}
    </EntityLayout.Route>`
            `const serviceEntityPage = (
  <EntityLayout>
    <EntityLayout.Route path="/" title="Overview">
      {overviewContent}
    </EntityLayout.Route>

    <EntityLayout.Route if={isCrossplaneAvailable} path="/crossplane-resources" title="Crossplane Resources">
      <CrossplaneAllResourcesTable />
    </EntityLayout.Route>
    <EntityLayout.Route if={isCrossplaneAvailable} path="/crossplane-graph" title="Crossplane Graph">
      <CrossplaneResourceGraph />
    </EntityLayout.Route>`
        ) | (
            str replace
            `const componentPage = (
  <EntitySwitch>`
            `const componentPage = (
  <EntitySwitch>
    <EntitySwitch.Case if={isComponentType('crossplane-claim')}>
      {serviceEntityPage}
    </EntitySwitch.Case>`
        ) | save packages/app/src/components/catalog/EntityPage.tsx --force

    open packages/backend/src/index.ts
        | (
            str replace
            `backend.start();`
            `backend.add(import('@vrabbi/backstage-plugin-crossplane-permissions-backend'));
backend.add(import('@vrabbi/backstage-plugin-kubernetes-ingestor'));
backend.add(import('@vrabbi/backstage-plugin-scaffolder-backend-module-terasky-utils'));

backend.start();`
        ) | save packages/backend/src/index.ts --force

    cd ..

    $"export NODE_OPTIONS=--no-node-snapshot\n" | save --append .env

}

def --env "main build backstage" [
    --image = "ghcr.io/vfarcic/backstage-demo"
    --tag = "0.1.0"
] {

    cd backstage

    yarn install --immutable

    yarn tsc

    yarn build:backend

    (
        docker image build
            --file packages/backend/Dockerfile
            --tag $"($image):($tag)"
            .
    )

    docker container run -it -p 7007:7007 $"($image):($tag)"

    cd ..

}