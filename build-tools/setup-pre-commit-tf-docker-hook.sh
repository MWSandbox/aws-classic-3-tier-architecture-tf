#!/bin/bash
# Sets up a hook for the docker version of pre-commit-terraform (https://github.com/antonbabenko/pre-commit-terraform)
readonly HOOK_PATH="./../.git/hooks/pre-commit"
readonly CONTAINER_NAME="pre-commit"
readonly IMAGE_NAME="pre-commit"
readonly REPO_PATH=$(git rev-parse --show-toplevel) 
readonly CHECKOV_IMAGE_NAME="bridgecrew/checkov"
readonly INFRACOST_API_KEY_LOCATION="$HOME/.config/infracost/credentials.yml"
readonly INFRACOST_API_KEY=$(grep "^api_key:" "${INFRACOST_API_KEY_LOCATION}"| cut -c10-)

if [[ -f "$HOOK_PATH" ]]; then
	rm $HOOK_PATH
fi

touch $HOOK_PATH

echo "#!/bin/bash
cd $REPO_PATH

# Cleanup old checkov containers
checkov_containers=\$(docker ps -a | grep $CHECKOV_IMAGE_NAME)
checkov_containers_count=\${#checkov_containers}
if [[ \$checkov_containers_count > 0 ]]; then
	docker rm \$(docker ps -a | awk '{ print \$1,\$2 }' | grep $CHECKOV_IMAGE_NAME | awk '{ print \$1 }')
fi

docker ps -a | grep $CONTAINER_NAME &> /dev/null
pre_commit_container_exists=\$?

if [[ pre_commit_container_exists -eq 0 ]]; then
    docker restart $CONTAINER_NAME && docker attach --no-stdin $CONTAINER_NAME
else
    docker run -e INFRACOST_API_KEY=$INFRACOST_API_KEY -v $REPO_PATH:/lint -v /home/ubuntu/.aws:/root/.aws -w /lint --name $CONTAINER_NAME $IMAGE_NAME run -a
fi" >> $HOOK_PATH

chmod +x $HOOK_PATH
