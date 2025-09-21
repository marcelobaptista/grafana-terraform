# Grafana Terraform Automation

Este projeto automatiza a importação de alguns recursos do Grafana para o Terraform, facilitando o gerenciamento de infraestrutura como código.
> **Aviso:** Este projeto pressupõe que você já tenha familiaridade com o funcionamento do Terraform, sua sintaxe e conceitos básicos. Recomenda-se entender como funciona o ciclo de vida dos recursos, importação e manipulação de estados antes de utilizar os scripts.

## Pré-requisitos

- Bash
- [curl](https://curl.se/)
- [jq](https://jqlang.org/)
- [Terraform (versão 1.0 ou superior)](https://developer.hashicorp.com/terraform/install)
- [Grafana Terraform Provider](https://registry.terraform.io/providers/grafana/grafana/latest)
- Token de API do Grafana com permissão de administração. O token deve ser gerado na organização correta, que deverá ser a mesma especificado no arquivo `variables.tf`. [Documentação oficial](https://grafana.com/docs/grafana/latest/developers/http_api/examples/create-api-tokens-for-org/)

## Estrutura

- `create-folders.sh`: Script para importar pastas do Grafana e criar os arquivos .tf necessários.
- `folders/`: Diretório que será gerado contendo os arquivos .tf das pastas do Grafana.
- `import-folders.sh`: Script gerado para importar pastas no Terraform.
- `import-teams.sh`: Script gerado para importar times no Terraform.
- `main.tf`: Arquivo de configuração principal do Terraform.
- `create-teams.sh`: Script para importar times do Grafana e criar os arquivos .tf necessários.
- `teams/`: Diretório  que será gerado contendo os arquivos .tf dos times do Grafana.
- `variables.tf`: Arquivo de variáveis do provider Grafana. Deverá ser configurado com os valores corretos de `grafana_auth`, `grafana_url` e `grafana_org_id`.

## Como usar

### 1. Importar pastas do Grafana

Execute o script `create-folders.sh` passando a URL do Grafana e o token de API:

```bash
./create-folders.sh https://grafana.seusite.com SEU_TOKEN
```

Isso irá:

- Consultar as pastas via API
- Gerar arquivos Terraform para cada pasta e suas permissões
- Criar o script `import-folders.sh` para importar os recursos no Terraform

#### Exemplo de uso do script de importação de pastas

>**Observação:** a opção `prevent_destroy_if_not_empty = true` é adicionada automaticamente para evitar a exclusão acidental de pastas que contêm dashboards ou outros recursos. Para remover essa proteção, basta editar no script `create-folders.sh` ou nos arquivos `.tf`gerados.

```bash
./import-folders.sh
```

### 2. Importar times do Grafana

Execute o script `create-teams.sh` passando a URL do Grafana e o token de API:

```bash
./create-teams.sh https://grafana.seusite.com SEU_TOKEN
```

Isso irá:

- Consultar os times via API
- Gerar arquivos Terraform para cada time
- Criar o script `import-teams.sh` para importar os recursos no Terraform

#### Exemplo de uso do script de importação de times

```bash
./import-teams.sh
```

## Exemplos de recursos gerados

### Pasta

```hcl
resource "grafana_folder" "minha-pasta" {
  title                         = "Minha Pasta"
  uid   = "abc123"
  prevent_destroy_if_not_empty = true
}

resource "grafana_folder_permission" "minha-pasta" {
  folder_uid = grafana_folder.minha-pasta.uid
  permissions {
    role       = "Viewer"
    permission = "View"
  }
}
```

### Subpasta

```hcl
resource "grafana_folder" "minha-subpasta" {
  title = "Minha Pasta"
  uid   = "abc123"
  parent_folder_uid            = grafana_folder.minha-pasta.uid
  prevent_destroy_if_not_empty = true
}

resource "grafana_folder_permission" "minha-pasta" {
  folder_uid = grafana_folder.minha-pasta.uid
  permissions {
    user_id       = "42" # user@example.com
    permission = "Edit"
  }
}
```

### Time

```hcl
resource "grafana_team" "meu-time" {
  name    = "Meu Time"
  email   = "meu-time@empresa.com"
  members = ["usuario1@empresa.com", "usuario2@empresa.com"]
}
```

## Observações

- Os scripts criam a estrutura de diretórios necessária.
- Os scripts geram módulos separados para os recursos.
- Os arquivos `.tf` são criados automaticamente para cada recurso.

## Licença

Este projeto está licenciado sob a [GNU General Public License v3.0 (GPLv3)](https://www.gnu.org/licenses/gpl-3.0.html).
Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
