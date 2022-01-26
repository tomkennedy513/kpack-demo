#!/usr/bin/env bash

#_ECHO_OFF
export REGISTRY="projects.registry.vmware.com"
export DEFAULT_REPO="$REGISTRY/ktom/kpack"
export REGISTRY_USERNAME="robot\$ktom+tom-robot"
export REGISTRY_PASSWORD=""

ytt -f kpack-values-template.yaml -v default_repository=$DEFAULT_REPO -v default_repository_username=$REGISTRY_USERNAME -v default_repository_password=$REGISTRY_PASSWORD > kpack-values.yaml
#_ECHO_ON

#_ECHO_# Prerequisite -> Install TCE
#_ECHO_# View Packages
tanzu package available list

#_ECHO_# Install kpack
tanzu package install kpack --package-name kpack.community.tanzu.vmware.com --version 0.5.0 --namespace kpack-install --values-file kpack-values.yaml --create-namespace

#_ECHO_# Check that kpack is running
kubectl get pods -n kpack

#_ECHO_# Create a ClusterStore
kp clusterstore save default --buildpackage gcr.io/paketo-buildpacks/go@sha256:3c782232f6dfbccf23a85ec240a5beceb66232b00f2f7115eb53ea5440433457

#_ECHO_# Create a ClusterStack
kp clusterstack save default --build-image paketobuildpacks/build:1.3.18-tiny-cnb --run-image paketobuildpacks/run:1.3.18-tiny-cnb

#_ECHO_# Create a ClusterBuilder
kp clusterbuilder save default --tag $DEFAULT_REPO/builder --stack default --store default --buildpack paketo-buildpacks/go

#_ECHO_# Create a Secret
kp secret create registry-secret --registry $REGISTRY --registry-user $REGISTRY_USERNAME

#_ECHO_# Create an Image
kp image save test-image --tag $DEFAULT_REPO/test-image --git https://github.com/paketo-buildpacks/samples --git-revision 284b0e4e432c0eeda078eb64810b13764719bcc9 --sub-path go/mod --cluster-builder default --wait
kp build list test-image

#_ECHO_# Patch an Image
kp image save test-image --git-revision 336ccc19f5be44901851530072ea3af4d007b26c --wait
kp build list test-image

#_ECHO_# Update a Buildpack
kp clusterstore add default --buildpackage gcr.io/paketo-buildpacks/go@sha256:1f7e664e9561f44f7e0af0f8030598027a9d4515f2672d803066d16fa5f0bd2a
kp build list test-image
kp build logs test-image

#_ECHO_# Update the Stack
kp clusterstack save default --build-image paketobuildpacks/build:tiny-cnb --run-image paketobuildpacks/run:tiny-cnb
kp build list test-image
kp build logs test-image

#_ECHO_# Questions?
