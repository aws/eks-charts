#!/bin/bash

check_old_crds() {

    vs=$(kubectl get crd virtualservices.appmesh.k8s.aws --ignore-not-found -o json | jq -r '.spec.versions[]? | select(.? | .name == "v1beta1")')
    vn=$(kubectl get crd virtualnodes.appmesh.k8s.aws --ignore-not-found -o json | jq -r '.spec.versions[]? | select(.? | .name == "v1beta1")')
    ms=$(kubectl get crd meshes.appmesh.k8s.aws --ignore-not-found -o json | jq -r '.spec.versions[]? | select(.? | .name == "v1beta1")')

    if [[ -z $vs && -z $vn && -z $ms  ]]; then
        echo "App Mesh CRD check: PASSED!"
        return 0
    else
       echo "App Mesh CRD check: FAILED -- v1beta1 CRDs are still installed"
       return 1
    fi

}

check_controller_version() {
    currentver=$(kubectl get deployment -n appmesh-system appmesh-controller --ignore-not-found -o json | jq -r ".spec.template.spec.containers[].image" | cut -f2 -d ':')
    requiredver="v1.0.0"

    if [[ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" || -z "$currentver" ]]; then
        echo "Controller version check: PASSED!"
        return 0
    else
        echo "Controller version check: FAILED -- old appmesh-controller ($currentver) is still running"
        return 1
    
    fi
}

check_injector() {
    status=0
    for ns in "appmesh-inject" "appmesh-system"; do

        injector=$(kubectl get deployment -n ${ns} appmesh-inject --ignore-not-found -o json | jq -r .kind)

        if [ -z $injector ]; then
            echo "Injector check for namespace ${ns}: PASSED!"
        else
           echo "Injector check: FAILED -- appmesh-inject is still running in namespace ${ns}"
           return 1
        fi

    done
    return 0
}

main() {

    exitcode=0

    check_old_crds || exitcode=1
    check_controller_version || exitcode=1
    check_injector || exitcode=1


    if [ ${exitcode} = 0 ]; then
        echo -e "\nYour cluster is ready for upgrade. Please proceed to the installation instructions"
    else
        echo -e "\nYour cluster is NOT ready for upgrade to v1.0.0. Please uninstall all the identified items before proceeding"
    fi
}

main
