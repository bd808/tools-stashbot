#!/usr/bin/env bash
# Management script for stashbot kubernetes processes

set -e

DEPLOYMENT=stashbot.bot
POD_NAME=stashbot.bot

CONFIG=etc/config-k8s.yaml

TOOL_DIR=$(cd $(dirname $0)/.. && pwd -P)
VENV=venv-k8s-py2
if [[ -f ${TOOL_DIR}/${VENV}/bin/activate ]]; then
    # Enable virtualenv
    source ${TOOL_DIR}/${VENV}/bin/activate
fi

_get_pod() {
    kubectl get pods \
        --output=jsonpath={.items..metadata.name} \
        --selector=name=${POD_NAME}
}

case "$1" in
    start)
        echo "Starting stashbot k8s deployment..."
        kubectl create -f ${TOOL_DIR}/etc/deployment.yaml
        ;;
    run)
        date +%Y-%m-%dT%H:%M:%S
        echo "Running stashbot..."
        cd ${TOOL_DIR}
        exec python stashbot.py --config ${CONFIG}
        ;;
    stop)
        echo "Stopping stashbot k8s deployment..."
        kubectl delete deployment ${DEPLOYMENT}
        # FIXME: wait for the pods to stop
        ;;
    restart)
        echo "Restarting stashbot k8s deployment..."
        $0 stop &&
        $0 start
        ;;
    status)
        echo "Active pods:"
        kubectl get pods -l name=${POD_NAME}
        ;;
    tail)
        exec kubectl logs -f $(_get_pod)
        ;;
    update)
        echo "Updating git clone..."
        cd ${TOOL_DIR}
        git fetch &&
        git --no-pager log --stat HEAD..@{upstream} &&
        git rebase @{upstream}
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|tail|update}"
        exit 1
        ;;
esac

exit 0
# vim:ft=sh:sw=4:ts=4:sts=4:et:
