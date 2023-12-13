# Demo 2 OpenShift Pipeline project config

Instructions to create and configure the pipeline in the production project for the demo 2.

0. Login as the user who runs the pipelines

    ~~~sh
    oc login -u developer https://api.crc.testing:6443
    ~~~

1. Create the *"production"* project

    ~~~sh
    oc new-project alumno
    ~~~

    ~~~output
    Now using project "alumno" on server "https://api.crc.testing:6443".
    ~~~

2.  Deploy the database

    ~~~sh
    oc create -f database/
    ~~~

    ~~~output
    secret/library-db-data created
    secret/library-db created
    service/library-db created
    deployment.apps/library-db created
    ~~~

3. Define the pipeline

    ~~~sh
    oc create -f pipeline
    ~~~

    ~~~output
    persistentvolumeclaim/library-shop-source created
    eventlistener.triggers.tekton.dev/library-shop created
    pipeline.tekton.dev/library-shop-pipeline created
    trigger.triggers.tekton.dev/libray-shop created
    triggerbinding.triggers.tekton.dev/library-shop created
    triggertemplate.triggers.tekton.dev/library-shop created
    ~~~

4. Test the pipeline

    Create the PipelineRun resource

    ~~~sh
    oc create -f pipelinerun/
    ~~~

    ~~~output
    pipelinerun.tekton.dev/library-shop-pr-b2tbf created
    ~~~

    Verify the pipeline was triggered

    ~~~sh
    tkn pr list
    ~~~

    ~~~output
    NAME                    STARTED          DURATION   STATUS
    library-shop-pr-b2tbf   11 seconds ago   ---        Running
    ~~~

5. (optional) Expose the eventlistener

    ~~~sh
    oc create route edge el-library-shop --service=el-library-shop --insecure-policy=Redirect -o yaml
    ~~~

    ~~~yaml
    apiVersion: route.openshift.io/v1
    kind: Route
    metadata:
        annotations:
            openshift.io/host.generated: "true"
    ...
    labels:
        app: library-shop-pipelines
        app.kubernetes.io/managed-by: EventListener
        app.kubernetes.io/part-of: Triggers
        eventlistener: library-shop
        group: rhacademy
    name: el-library-shop
    namespace: alumno
    ...
    spec:
        host: el-library-shop-alumno.apps-crc.testing
        port:
            targetPort: http-listener
        tls:
            insecureEdgeTerminationPolicy: Redirect
            termination: edge
        to:
            kind: Service
            name: el-library-shop
            weight: 100
        wildcardPolicy: None
    ~~~
