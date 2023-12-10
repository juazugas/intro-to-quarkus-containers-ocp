# Deploy the Library Shop Application in OpenShift

In this lab we are going to see how we can use Java with Quarkus to build and run containers in our local system.

## Lab 1 - Deploy &nbsp; *as a Developer* &nbsp; the Quarkus application

1. Connect to the Fedora 39 system
2. Clone the application and change into the created directory

3. Generate the application binaries (only if demo1 was not done)

    For the JVM binaries run the command:

    ~~~sh
    ./mvnw package
    ~~~

    For the native image run the command:

    ~~~sh
    ./mvnw package -Dnative -Dquarkus.native.container-build=true -Dquarkus.native.container-runtime=podman
    ~~~

4. Login into OpenShift

    1. Access the [OpenShift Console URL](https://console-openshift-console.apps-crc.testing/)
    2. Access the "User menu" and open "Copy login command" option
    3. Display and copy the login command with the token

    ~~~sh
    oc login --token=sha256~Ke3yfBYcJP8vqGTbB-DwJQeKFcypwfq1vKPFlGsQBWU --server=https://api.crc.testing:6443
    ~~~

    ~~~output
    You have access to the following projects and can switch between them with 'oc project <projectname>':

    Using project "".
    ~~~

5. Create the "dev" project

    ~~~sh
    oc new-project alumno-n1--dev
    ~~~

    ~~~output
    Now using project "alumno-n1--dev" on server "https://api.crc.testing:6443".
    ~~~

    or switch to the project if already exists

    ~~~sh
    oc project alumno-n1--dev
    ~~~

    ~~~output
    Already on project "alumno-n1--dev" on server "https://api.crc.testing:6443".
    ~~~

6. (optional) Deploy the database

    Create the secret with the DDL

    ~~~sh
    oc apply -f https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/dev/database.ddl.yaml
    ~~~

    Apply the resources for the deployment

    ~~~sh
    oc apply -f https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/dev/database.deployment.yaml
    ~~~

7. Launch the build for the application in OpenShift

    ~~~sh
    ./mvnw oc:build
    ~~~

    ~~~output
    ...
    [INFO] oc: Build library-shop-s2i-1 in status Complete
    [INFO] oc: Found tag on ImageStream library-shop tag: sha256:60da633a...
    [INFO] oc: ImageStream library-shop written to .../library-shop/target/library-shop-is.yml
    ~~~

    Check the generated elements

    ~~~sh
    oc status
    ~~~

    ~~~output
    In project alumno-n2--test on server https://api.crc.testing:6443

    bc/library-shop-s2i source builds uploaded code on quay.io/quarkus/ubi-quarkus-native-binary-s2i:1.0
        -> istag/library-shop:1.0.0
        build #1 succeeded 11 minutes ago
    ~~~

    ~~~sh
    oc get pods -l openshift.io/build.name=library-shop-s2i-1
    ~~~

    ~~~output
    NAME                       READY   STATUS      RESTARTS   AGE
    library-shop-s2i-1-build   0/1     Completed   0          11m
    ~~~

8. Deploy the application

    ~~~sh
    ./mvnw oc:resource oc:apply
    ~~~

    ~~~output
    [INFO] --- oc:1.15.0:apply (default-cli) @ library-shop ---
    [INFO] oc: OpenShift platform detected
    [INFO] oc: Using OpenShift at https://api.crc.testing:6443/ in namespace null with manifest target/classes/META-INF/jkube/openshift.yml
    [INFO] oc: Creating a Secret in alumno-n2--test namespace with name library-shop from openshift.yml
    [INFO] oc: Created Secret: target/jkube/applyJson/alumno-n2--test/secret-library-shop.json
    [INFO] oc: Creating a Service in alumno-n2--test namespace with name library-shop from openshift.yml
    [INFO] oc: Created Service: target/jkube/applyJson/alumno-n2--test/service-library-shop.json
    [INFO] oc: Creating a ConfigMap in alumno-n2--test namespace with name library-shop from openshift.yml
    [INFO] oc: Created ConfigMap: target/jkube/applyJson/alumno-n2--test/configmap-library-shop.json
    [INFO] oc: Creating a Deployment in alumno-n2--test namespace with name library-shop from openshift.yml
    [INFO] oc: Created Deployment: target/jkube/applyJson/alumno-n2--test/deployment-library-shop.json
    [INFO] oc: Creating Route alumno-n2--test:library-shop host: null
    [INFO] oc: HINT: Use the command `oc get pods -w` to watch your pods start up
    ~~~

    Watch the pods

    ~~~sh
    oc get pods -w
    ~~~

    ~~~output
    NAME                            READY   STATUS      RESTARTS   AGE
    library-db-69f74cb64c-snvf6     1/1     Running     0          22m
    library-shop-5cfffb9db8-phlrx   1/1     Running     0          6m23s
    library-shop-s2i-1-build        0/1     Completed   0          21m
    ~~~

    NOTE: Ctrl+C to exit from the watch

9. Check the application is working correctly

    Get the generated route host

    ~~~sh
    oc get route library-shop --template='{{ .spec.host }}'
    ~~~

    ~~~output
    library-shop-alumno-n1--dev.apps-crc.testing
    ~~~

    Request the application data

    ~~~sh
    curl -k -s https://library-shop-alumno-n2--dev.apps-crc.testing/ehlo
    ~~~

    ~~~output
    ehlo from version v1 host library-shop-5cfffb9db8-phlrx
    ~~~

    ~~~sh
    curl -k -s https://library-shop-alumno-n2--dev.apps-crc.testing/ehlo/database
    ~~~

    ~~~output
    ehlo from PostgreSQL 15.3 on x86_64-redhat-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-18), 64-bit
    ~~~

    ~~~sh
    curl -k -s https://library-shop-alumno-n2--dev.apps-crc.testing/hello
    ~~~

    ~~~sh
    curl -k -s https://library-shop-alumno-n2--dev.apps-crc.testing/library
    ~~~

## Lab 2 - Deploy &nbsp; *in production* &nbsp; the Quarkus application

1. Change to the production namespace

    ~~~sh
    oc project alumno-n1
    ~~~

    ~~~output
    Now using project "alumno-n1" on server "https://api.crc.testing:6443".
    ~~~

    TODO: add a link to the README.md in the demo2-assets directory how to configure the pipeline in the namespace

2. Inspect the OpenShift Pipeline resource

    ~~~sh
    oc get pipeline --show-labels
    ~~~

    ~~~output
    NAME                    AGE   LABELS
    library-shop-pipeline   35m   app=library-shop-pipelines,group=rhacademy
    ~~~

    Check the OpenShift console for a visual representation of the pipeline

    1. Get the console URL

        ~~~sh
        oc whoami --show-console
        ~~~

    2. Access the console URL in your favourite browser
    3. Open (right menu) the Pipelines option and click on the `library-shop-pipeline`

    4. Explore the pipeline details

3. Execute the pipeline

    ~~~sh
    tkn pipeline start library-shop-pipeline \
        -w name=shared-workspace,volumeClaimTemplateFile=https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/prod/pipeline/library-shop-source.pvc.yaml \
        --prefix-name=library-shop-build- \
        --serviceaccount=pipeline \
        -p deployment-name=library-shop \
        -p git-url=https://github.com/juazugas/rha-quarkus-library-shop.git \
        -p backend-image=image-registry.openshift-image-registry.svc:5000/alumno/library-shop:1.0.0 \
        -l group=rhacademy,app=library-shop \
        --use-param-defaults
    ~~~

4. Check the running pipeline

    via command :

    ~~~sh
    tkn pr ls
    ~~~

    ~~~output
    NAME                        STARTED          DURATION   STATUS
    library-shop-build--nkvj2   20 seconds ago   ---        Running
    ~~~

    via the Web console on the Pipelines section

5. (optional) Configure the webhook to automatically launch the pipeline

    1. Get the EventListener route host

    ~~~sh
    oc get route el-library-shop --template='{{ .spec.host }}'
    ~~~

    2. Define the Webhook in github

    3. Check the status of the Trigger and EventListener via the Administrator console \
    (Administrator -> Pipelines -> Triggers)