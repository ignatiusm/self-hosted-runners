#!/bin/bash

export RUNNER_USERNAME=$(id -un)
export RUNNER_USERGROUP=$(id -gn)

export AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache

cd /opt/actions-runner

if [[ -z "${RUNNER_NAME}" ]]; then
    RUNNER_NAME="singularity-$(hostname)"
fi

ACTIONS_URL="https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/registration-token"
echo "Requesting registration URL at '${ACTIONS_URL}'"

PAYLOAD=$(curl -sX POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${PERSONAL_ACCESS_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" ${ACTIONS_URL})
export RUNNER_TOKEN=$(echo $PAYLOAD | jq .token --raw-output)

printf "\n\033[0;44m---> Configuring the runner.\033[0m\n"
./config.sh \
    --name ${RUNNER_NAME} \
    --token ${RUNNER_TOKEN} \
    --url https://github.com/${GITHUB_ORG}/${GITHUB_REPO} \
    --work ${RUNNER_WORKDIR} \
    --labels "singularity,github" \
    --unattended \
    --replace

remove_runner() {
    printf "\n\033[0;44m---> Removing the runner.\033[0m\n"
    ./config.sh remove --unattended --token "${RUNNER_TOKEN}"
}

# run remove_runner function if "./run.sh" script is interrupted
trap "remove_runner" EXIT SIGINT SIGTERM KILL

printf "\n\033[0;44m---> Starting the runner.\033[0m\n"
./run.sh "$*" &
wait $!
