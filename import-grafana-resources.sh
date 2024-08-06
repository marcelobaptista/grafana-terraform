#!/bin/bash

grafana_tf_version=$(
  curl -s "https://api.github.com/repos/grafana/terraform-provider-grafana/releases/latest" |
    jq -r '.tag_name | sub("^v"; "")'
)

while true; do
    printf "Digite o org_id: "
    read -r org_id

    if [[ "${org_id}" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Por favor, insira apenas números."
    fi
done

while true; do
    printf "Digite o nome da organização: "
    read -r org_name

    if [ -n "${org_name}" ]; then
        break
    else
        echo "O nome da organização não pode ser vazio."
    fi
done

if [ -d "./${org_name}" ]; then
    echo "O diretório ${org_name} já existe. Deseja deletá-lo? (y/n)   "
    read -r answer
    if [ "${answer}" == "y" ]; then
        rm -rf "./${org_name}"
        mkdir -p "./${org_name}"
        cp -r scripts "./${org_name}/"
        echo "Diretório deletado e recriado com sucesso."
    else
        echo "O diretório não foi deletado."
    fi
else
    mkdir -p "./${org_name}"
    cp -r scripts "./${org_name}/"
fi

while true; do
    printf "Digite o token do Grafana: "
    read -r token_key

    if [ -n "${token_key}" ]; then
        break
    else
        echo "O token do Grafana não pode ser vazio. Por favor, tente novamente."
    fi
done

while true; do
    printf "Digite a URL do Grafana (ex: http://127.0.0.1:3000): "
    read -r grafana_url

    if [ -n "${grafana_url}" ]; then
        break
    else
        echo "A URL do Grafana não pode ser vazia."
    fi
done

while true; do
    printf "Digite o nome do usuário admin: "
    read -r admin_user

    if [ -n "${admin_user}" ]; then
        break
    else
        echo "O nome do usuário admin não pode ser vazio."
    fi
done

while true; do
    printf "Digite a senha do usuário admin: "
    read -rs admin_password

    if [ -n "${admin_password}" ]; then
        break
    else
        echo "A senha do usuário admin não pode ser vazia."
    fi
done

sed -i "s/version = \">=/version = \">= ${grafana_tf_version}/g" ./"${org_name}"/scripts/*.sh
sed -i "s/org_id=/org_id=${org_id}/g" ./"${org_name}"/scripts/*.sh
sed -i "s/org_name=/org_name=\"${org_name}\"/g" ./"${org_name}"/scripts/*.sh
sed -i "s/grafana_token=/grafana_token=\"${grafana_token}\"/g" ./"${org_name}"/scripts/*.sh
sed -i "s/grafana_url=/grafana_url=\"${grafana_url}\"/g" ./"${org_name}"/scripts/*.sh
sed -i "s/admin_user=/admin_user=\"${admin_user}\"/g" ./"${org_name}"/scripts/*.sh
sed -i "s/admin_password=/admin_password=\"${admin_password}\"/g" ./"${org_name}"/scripts/*.sh

mkdir -p ./"${org_name}"/modules/{folders,organizations,teams}

./"${org_name}"/scripts/create-tf-files.sh
./"${org_name}"/scripts/create-folders_tf.sh
./"${org_name}"/scripts/create-organization_tf.sh
./"${org_name}"/scripts/create-teams_tf.sh

echo "Todos os scripts foram executados com sucesso."

rm -rf ./"${org_name}/scripts"
