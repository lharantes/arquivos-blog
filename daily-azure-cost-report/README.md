# Relatório diário de custos no Microsoft Azure por e-mail

Criar um relatório diário com o custo atual da assinatura, uma previsão dos gastos no mês e receber isso por e-mail, o script foi criado usando Powershel e MsGraph.

## Visão Geral

Eu tenho o hábito de toda manhã ler os meus e-mails e recebendo o relatório de gastos do Azure logo no início do dia eu já abro o portal do Microsoft Azure e apago ou desligo o recurso que está sendo usado sem necessidade.

## Pré-requisitos

- Powershell instalado se for executar localmente
- Permissões da identidade gerenciada: `Cost management reader` nas Assinaturas que irá gerar o custo
- Azure PowerShell Modules: `Microsoft.Graph.Applications`, `Microsoft.Graph.Authentication`, `Microsoft.Graph.Mail` e `Microsoft.Graph.Users.Actions`

## Script com créditos

Eu tenho assinaturas com créditos cedidos pela microsoft e o intuito é ir acompanhando esses gastos,  o e-mail que recebo com o relatório é o da imagem abaixo e para esse cenário use o script `daily-repor-no-credit.ps1`:

![daily-azure-cost-report](https://arantes.net.br/assets/img/36/01.png)
