# Introduction to Quarkus Development with Containers / OpenShift

## Prerequisities

List of fedora packages that need to be installed

```
java-21-openjdk
java-21-openjdk-devel
java-21-openjdk-headless
java-21-openjdk-javadoc
java-21-openjdk-src
podman
curl
jq
```

## Resources

Container Images that will be used:

```sh
docker.io/testcontainers/ryuk:0.12.0
docker.io/library/postgres:17
registry.access.redhat.com/ubi9/openjdk-21:1.24
registry.access.redhat.com/ubi9/openjdk-21-runtime:1.24
registry.access.redhat.com/ubi9/ubi-minimal:9.7
quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-21
quay.io/quarkus/ubi9-quarkus-micro-image:2.0
```


## Download artifacts

List of maven commands that will be used:

```sh
./mvnw clean
./mvnw validate compile test package
./mvnw verify
```

- Interactive commands

```sh
./mvnw quarkus:dev
./mvnw quarkus:test
```

- Container building

```sh
./mvnw package -Pjib
./mvnw package -Pdocker
./mvnw package -Ppodman
```

- Native binary building

```sh
./mvnw package -Dnative -Dquarkus.native.builder-image.pull=never -Dquarkus.native.container-build=true -Dquarkus.native.container-runtime=podman
./mvnw test-compile failsafe:integration-test -Dnative
```

- Build container with native binary

```sh
./mvnw verify -DskipTests -Dnative -Pdocker -Dquarkus.container-image.name=library-shop-docker-native -Dquarkus.native.reuse-existing=true
./mvnw verify -DskipTests -Dnative -Ppodman -Dquarkus.container-image.name=library-shop-docker-native -Dquarkus.native.reuse-existing=true
./mvnw package -DskipTests -Dnative -Pjib -Dquarkus.container-image.name=library-shop-jib-native -Dquarkus.native.reuse-existing=true
```
