# Projeto Automação Push Commands em Switches modelo HP2530-24G

Projeto criado para manter os scripts de automação para push de comandos dos switches HP 2530-24G de forma distribuida, versionada e economizar tempo de operação. Com este script é possível executar qualquer comando nos switches HP2530 em grande escala.

## Pré-requisitos para utilização deste projeto :exclamation:

Para pleno funcionamento deste projeto, você precisará:
- TER INSTALADO O MÓDULO POSH-SSH NO SEU POWERSHELL
- TER A LISTA DE IPS DOS SWITCHES QUE DESEJA DAR PUSH DE COMANDOS
- SETAR HORARIO DE VERAO NA FUNCTION "/scripts/functions/function02-synctime.psm1"

## Como Utilizar este projeto

**Na pasta "Scripts" há um Script principal:**<br />
1 - "1-pushcommands-hp2530.ps1"
Neste script é necessário inserir os comandos desejados para execução em massa.<br />
[Para acessar esse script clique aqui](/scripts/1-pushcommands-hp2530.ps1)

**Na pasta "Scripts\functions\" há duas functions que são utilizadas pelos scripts principais, são elas:**<br />
1 - "function01-hp2530.psm1"<br />
Esta function é utilizada pelos scripts principais para invoke de comandos nos switches HP2530<br />
[Para acessar essa function clique aqui](scripts/functions/function01-hp2530.psm1)

2 - "function02-synctime.psm1"<br />
Esta função é utilizada pelos scripts principais para configurações de SNTP no switch, e posterior verificação/comparação da hora entre o Switche e o S.O. onde o Script está sendo rodado.<br />
[Para acessar essa function clique aqui](scripts/functions/function02-synctime.psm1)

**Na pasta "Scripts" existe um arquivo CSV que contém a lista de IPs dos switches a serem atualizados. Altere essa lista conforme sua necessidade:**<br />
1 - "ips-switches.csv"<br />
[Para acessar esse arquivo com a lista de IPs clique aqui](scripts/ips-switches.csv)

**Na pasta "Scripts" existe um arquivo txt onde são guardados todos os LOGs que os scripts geram:**<br />
1 - "log.txt"<br />
[Para acessar esse arquivo de log clique aqui](scripts/log.txt)

**Na pasta "Scripts" há um arquivo referente à criptografia das credenciais para acesso SSH:**<br />
1 - "pass.xml"<br />
Este .xml é o arquivo gerado pelo script principal, com base nas credenciais digitadas pelo usuário. Nele contem um hash criptografado da senha digitada para conexão SSH nos switches.<br />
[Para acessar esse arquivo .xml clique aqui](scripts/pass.xml)



