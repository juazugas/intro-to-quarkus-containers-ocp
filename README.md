# Introduction to Quarkus Development with Containers / OpenShift

## Prerequisities

List of fedora packages that need to be installed

    ~~~
    java-21-openjdk
    java-21-openjdk-devel
    java-21-openjdk-headless
    java-21-openjdk-javadoc
    java-21-openjdk-src
    podman
    podman-compose
    podman-remote
    podman-docker
    curl
    jq
    ~~~

Binary dependencies:

    ~~~sh
    # kubectl and oc
    curl -L https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.20.9/openshift-client-linux-4.20.9.tar.gz -o /tmp/oc.tar.gz && sudo tar -C /usr/local/bin -xzf /tmp/oc.tar.gz oc kubectl && sudo chmod +x /usr/local/bin/oc /usr/local/bin/kubectl
    # tkn
    curl https://mirror.openshift.com/pub/openshift-v4/amd64/clients/pipelines/latest/tkn-linux-amd64.tar.gz -o /tmp/tkn.tar.gz && sudo tar -C /usr/local/bin -xzf /tmp/tkn.tar.gz tkn && sudo chmod +x /usr/local/bin/tkn
    # Visual Studio Code
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null && sudo dnf install code -y
    ~~~

## Container Image Resources

Container Images that will be used:

    ~~~sh
    docker.io/testcontainers/ryuk:0.12.0
    docker.io/library/postgres:17
    registry.access.redhat.com/ubi9/openjdk-21:1.24
    registry.access.redhat.com/ubi9/openjdk-21-runtime:1.24
    registry.access.redhat.com/ubi9/ubi-minimal:9.7
    quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-21
    quay.io/quarkus/ubi9-quarkus-micro-image:2.0
    ~~~

## Required Visual Studio Code extensions

    ~~~sh
    # Java and Quarkus extensions
    # redhat.vscode-quarkus vscjava.vscode-java-pack redhat.vscode-microprofile redhat.vscode-yaml redhat.vscode-xml
    code --install-extension vscjava.vscode-java-pack
    code --install-extension redhat.vscode-quarkus
    code --install-extension redhat.vscode-microprofile
    code --install-extension redhat.vscode-yaml
    code --install-extension redhat.vscode-xml
    ~~~

## Pre-Download Java and Maven artifacts

List of maven commands that will be used:

    ~~~sh
    ./mvnw clean
    ./mvnw validate compile test package
    ./mvnw verify
    ~~~

Interactive commands

    ~~~sh
    ./mvnw quarkus:dev
    ./mvnw quarkus:test
    ~~~

Container building

    ~~~sh
    ./mvnw package -Pjib
    ./mvnw package -Pdocker
    ./mvnw package -Ppodman
    ~~~

Native binary building

    ~~~sh
    ./mvnw package -Dnative -Dquarkus.native.builder-image.pull=never -Dquarkus.native.container-build=true -Dquarkus.native.container-runtime=podman
    ./mvnw test-compile failsafe:integration-test -Dnative
    ~~~

Build container with native binary

    ~~~sh
    ./mvnw verify -DskipTests -Dnative -Pdocker -Dquarkus.container-image.name=library-shop-docker-native -Dquarkus.native.reuse-existing=true
    ./mvnw verify -DskipTests -Dnative -Ppodman -Dquarkus.container-image.name=library-shop-docker-native -Dquarkus.native.reuse-existing=true
    ./mvnw package -DskipTests -Dnative -Pjib -Dquarkus.container-image.name=library-shop-jib-native -Dquarkus.native.reuse-existing=true
    ~~~

    In case of limited resources, there are properties to limit the resources used by the container builder:

    ~~~sh
    -Dquarkus.native.container-runtime-options="--cpus=4,--memory=6G"
    ~~~

## Configure lab environment

As the user we are going to use podman as the container runtime, we need to configure the environment variables to use podman.

    ~~~sh
    systemctl --user enable podman.socket --now
    cat << __EOF >> ~/.bashrc

    # Lab environment variables
    DOCKER_HOST=unix:///run/user/${UID}/podman/podman.sock
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk
    TESTCONTAINERS_RYUK_DISABLED=false

    export DOCKER_HOST JAVA_HOME TESTCONTAINERS_RYUK_DISABLED
    __EOF
    ~~~

## Labs requirements

The labs in this repo were tested in a Fedora 43 system with the following hardware and software versions:

Hardware:

- 4 vCPUs
- 8 GiB RAM
- 40 GB HD

## Preparing the system for the labs

1. Create the script that prepares the VM

    ~~~sh
    cat << EOF > prepare_env.sh
    #!/bin/bash

    sudo dnf5 group install workstation-product-environment -y
    sudo systemctl set-default graphical.target
    sudo useradd student -G wheel
    echo "student:student" | chpasswd
    # sudo dnf install -y podman podman-compose virtualbox-guest-additions
    sudo dnf install -y java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless java-21-openjdk-javadoc java-21-openjdk-src podman podman-compose podman-remote podman-docker curl jq
    sudo dnf remove java-25-openjdk-headless
    # kubectl and oc
    curl -L https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.20.9/openshift-client-linux-4.20.9.tar.gz -o /tmp/oc.tar.gz && sudo tar -C /usr/local/bin -xzf /tmp/oc.tar.gz oc && sudo chmod +x /usr/local/bin/oc /usr/local/bin/kubectl
    curl https://mirror.openshift.com/pub/openshift-v4/amd64/clients/pipelines/latest/tkn-linux-amd64.tar.gz -o /tmp/tkn.tar.gz && sudo tar -C /usr/local/bin -xzf /tmp/tkn.tar.gz tkn && sudo chmod +x /usr/local/bin/tkn
    # Visual Studio Code
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null && sudo dnf install code -y
    # Container images
    sudo -iu student podman pull docker.io/testcontainers/ryuk:0.12.0
    sudo -iu student podman pull docker.io/library/postgres:17
    sudo -iu student podman pull registry.access.redhat.com/ubi9/openjdk-21:1.24
    sudo -iu student podman pull registry.access.redhat.com/ubi9/openjdk-21-runtime:1.24
    sudo -iu student podman pull registry.access.redhat.com/ubi9/ubi-minimal:9.7
    sudo -iu student podman pull quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-21
    sudo -iu student podman pull quay.io/quarkus/ubi9-quarkus-micro-image:2.0
    sudo -iu student podman pull docker.io/library/hello-world:latest
    sudo -iu student podman pull docker.io/library/httpd:2.4
    # Java and Quarkus extensions
    # redhat.vscode-quarkus vscjava.vscode-java-pack redhat.vscode-microprofile redhat.vscode-yaml redhat.vscode-xml
    sudo -iu student code --install-extension vscjava.vscode-java-pack
    sudo -iu student code --install-extension redhat.vscode-quarkus
    sudo -iu student code --install-extension redhat.vscode-microprofile
    sudo -iu student code --install-extension redhat.vscode-yaml
    sudo -iu student code --install-extension redhat.vscode-xml

    sudo reboot

    EOF
    ~~~

2. Create the VM

    ~~~sh
    kcli create vm -i fedora43 -P numcpus=4 -P memory=8192 -P name=rha-2026 -P disks=[40] -P scripts=[prepare_env.sh]
    ~~~