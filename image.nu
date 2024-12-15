#!/usr/bin/env nu

# Builds a container image
def "main build image" [
    tag: string                    # The tag of the image (e.g., 0.0.1)
    --registry = "ghcr.io" # Image registry (e.g., ghcr.io)
    --registry_user = "vfarcic"    # Image registry user (e.g., vfarcic)
    --image = "silly-demo"         # Image name (e.g., silly-demo)
    --builder = "docker"           # Image builder; currently supported are: `docker` and `kaniko`
    --push = true                  # Whether to push the image to the registry
    --dockerfile = "Dockerfile"    # Path to Dockerfile
] {

    if $builder == "docker" {

        (
            docker image build
                --tag $"($registry)/($registry_user)/($image):latest"
                --file $dockerfile
                .
        )

        (
            docker image tag
                $"($registry)/($registry_user)/($image):latest"
                $"($registry)/($registry_user)/($image):($tag)"
        )

        if $push {

            docker image push $"($registry)/($registry_user)/($image):latest"

            docker image push $"($registry)/($registry_user)/($image):($tag)"
        }

    } else if $builder == "kaniko" {

        (
            executor --dockerfile=Dockerfile --context=.
                $"--destination=($registry)/($registry_user)/($image):($tag)"
                $"--destination=($registry)/($registry_user)/($image):latest"
        )

    } else {

        echo $"Unsupported builder: ($builder)"

    } 

}

