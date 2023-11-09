# Scripts para Configuração do Ambiente Grafana

Este repositório contém scripts para a importação de um ambiente Grafana para ser gerenciado através do Terraform usando [Terraform Grafana Provider](https://registry.terraform.io/providers/grafana/grafana/2.5.0).

O Terraform Grafana Provider é uma extensão do Terraform que permite a automação da configuração e gerenciamento de recursos no Grafana.

Principais benefícios:

- Automatiza a configuração do Grafana.
- Permite o versionamento e controle de configuração.
- Garante a reprodutibilidade de ambientes.
- Estabelece padrões de configuração para consistência.
- Facilita a escalabilidade da configuração.
- Mantém o estado do ambiente para melhor gestão.
- Oferece maior visibilidade e controle sobre as alterações.
- Reduz a chance de erros manuais.

Esses benefícios trazem eficiência, consistência e segurança na configuração e gerenciamento de recursos no Grafana.

# ATENÇÃO

Lembrando que, como em qualquer ferramenta, é importante entender bem o funcionamento do Terraform e do Grafana antes de implementar essa abordagem em um ambiente de produção. Além disso, sempre faça testes em ambientes de não produção para garantir que a configuração automatizada funcione conforme o esperado.

No momento só há as possibilidades de importartar folders, teams, organization e usuários¹.

## Pré-requisitos

- [curl](https://curl.se/)
- [jq](https://jqlang.github.io/jq/)
- [Service Account Token Grafana](https://grafana.com/docs/grafana/latest/developers/http_api/create-api-tokens-for-org/) para a org. desejada, com permissão de Admin
- [terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform)

## Descrição de cada script

Todos os scripts utilizam a API do Grafana para criar os arquivos para o Terraform já configurados.

### `import-grafana-resources.sh`

Script a ser executado diretamente, pois irá executar os demais, solicitando antes os dados de acesso, API token, etc.

### `create-tf-files.sh`

Cria a estrutura de diretórios e arquivos necessários para iniciar um projeto com o Terraform.

### `create-folders.sh`

Importa as pastas no Grafana e suas permissões de acesso, irá criar o módulo Terraform "folders.

### `create-organization.sh`

Importa a organização escolhida no Grafana, irá criar o módulo Terraform "organizations.

### `create-teams.sh`

Importa as equipes no Grafana e usuários associados, irá criar o módulo Terraform "teams.

---

## Execução do script

Ao executar o script `import-grafana-resources.sh` serão solicitadas as informações sobre o ambiente Grafana a ser importado.

```bash
$ ./import-grafana-resources.sh
Digite o org_id: 1
Digite o nome da organização: Casa
Digite o token do Grafana: glsa_y3cLqIAgYomZBElTfs4G9nHGOEdHRsca_cec7f570
Digite a URL do Grafana (ex: http://127.0.0.1:3000): http://127.0.0.1:3000
Digite o nome do usuário admin: admin
Digite a senha do usuário admin:
```

Após a execução, serão criados arquivos e pastas obedecendo a seguinte estrutura:

```
<nome da organização>
├── import-<nome da organização>-resources.sh
├── modules
│   ├── folders
│   │   ├── folder-1.tf
│   │   └── main.tf
│   ├── organizations
│   │   ├── main.tf
│   │   ├── org_admins.tf
│   │   ├── organization.tf
│   │   ├── org_editors.tf
│   │   └── org_viewerss.tf
│   ├── teams
│   │   └── main.tf
├── modules.tf
└── providers.tf
```

## Utilização no Terraform

Acesse a pasta <nome da organização>, e execute o arquivo import-<nome da organização>-resources.sh para realizar a importação do ambiente para o Terraform. Após bem sucedido, basta executar, mas verifique antes durante o "plan" se nenhum recurso será destruído antes de aplicar.
:

```bash
$ terraform plan
$ terraform apply
```

## Como fazer a gestão de times e pastas no Grafana após a importação?

- Para incluir um usuário em um organization, folder ou team, o mesmo deverá ser criado no Grafana previamente, caso contrário, não funcionará.
- Tenha em mente que qualquer alteração realizada no Grafana fora do Terraform precisará ser importada pelo Terraform para aplicar, caso contrário, a automação do Terraform sobrescreverá qualquer alteração relativa a folder, team ou organizations feita pela interface.

## _[1] Como faço a gestão de usuários (criação, remoção) pelo Terraform?_

Como não há possbilidade de importar as senhas dos usuários do Grafana através da API, não foi incluído o script para importação de usuários no script principal. Mas caso queira, há o script `create-grafana_users.sh` na pasta scripts que criará os arquivos necessários, bastando somente editar as variáveis e colocar as senhas dos usuários no arquivo. (Não recomendado)

Após isso, acesse a pasta <nome da organização> e faça as seguintes modificações no arquivo `modules.tf`:

```terraform
module "users" {
  source = "./modules/users"
  providers = {
    grafana = grafana.basic
  }
}
```

Na linha `source     = "./modules/organizations"`, adicione abaixo:

depends_on = [module.users]

Na linha `source     = "./modules/teams"`, adicione abaixo:

depends_on = [module.organizations, module.users]

Na linha `  source     = "./modules/folders"`, adicione abaixo:

depends_on = [module.users, module.teams]
