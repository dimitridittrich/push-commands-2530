<#
Script de automacao para execução de comandos em massa nos switches HP2530-24G
Autor: Dimitri Dittrich
Data: 19/04/2018
#>

#------------AUTOMATIC-PATH-------------"
$completo = $MyInvocation.MyCommand.Path
$scriptname = $MyInvocation.MyCommand.Name
$caminho = $completo -replace $scriptname, ""
#---------------------------------------"
cls


Write-Host "`n"
Write-Host "`n"
#----------MODULOS-CAMINHOS-VARIAVEIS-----------"
$cont = 0
$final_verification = "y"

#PRE-REQUISITOS E VALORES A SEREM ALTERADOS CONFORME NECESSIDADE
#Necessario ter instalado o modulo posh-ssh
#Alterar horario de versao na funcion timesync conforme necessidade
$csvfile = "$caminho.\ips-switches.csv"
[string]$arqpassencrypted ="$caminho.\pass.xml"
$pathlog = "$caminho.\log.txt"
$synctime = ''
$test_validation = "False"

Import-Module -name posh-ssh
Remove-Module "function01-hp2530"
Import-Module "$caminho.\functions\function01-hp2530.psm1"
Remove-Module "function02-synctime"
Import-Module "$caminho.\functions\function02-synctime.psm1"
cls
#----------------------------------------------"

Write-Host "`n"
Write-Host "`n"
Write-Host "#########----------CREDENCIAIS-SSH-----------#########"
$encpwd = Get-Credential | Export-Clixml -Path "$caminho.\pass.xml"
Write-Host "#########------------------------------------#########"

Write-Host "`n"
Write-Host "`n"
Write-Host "#########----------PING-SW-----------#########"
$ColumnHeader = "IPaddress"
Write-Host "Reading file" $csvfile
$ipaddresses = import-csv $csvfile | select-object $ColumnHeader

foreach($ip in $ipaddresses) {
$cont = 0
$ipaddress = $ip.("IPAddress")
    Write-Host "Teste de ping no switch de ip $ipaddress da lista CSV"
    while ($cont -le 2) {

    if (test-connection $ip.("IPAddress") -count 1 -quiet) {
        write-host $ip.("IPAddress") "Ping succeeded." -foreground green
        #variavel ipaddress recebe o ip que esta na vez do csv
        $cont = 4

Remove-SSHSession -Index 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
Write-Host "#########-----------------------------#########"

Write-Host "`n"
Write-Host "`n"
Write-Host "--------CONEXAO-SSH---------"
$cred = Import-Clixml -Path $arqpassencrypted

Write-Host ">>>>>Cria sessao<<<<<"
$retorno_ssh = New-SSHSession -ComputerName $ipaddress -AcceptKey -Credential $cred -Verbose           

            Write-Host ">>>>>VALIDA-CONEXAO<<<<<"
            
            if ($retorno_ssh.Connected)
            {
            $date = get-date
            Write-Host "CONEXÃO SSH no Switch de IP $ipaddress REALIZADA COM SUCESSO!"
            [string]$log = $date.ToString() + " - CONEXAO SSH no Switch de IP " + $ipaddress.ToString() + " REALIZADA COM SUCESSO!"
            Add-Content -Path $pathlog -Value $log
            }
                else
                {
                $date = get-date
                Write-Host "CONEXÃO SSH no Switch de IP $ipaddress NÃO DEU CERTO!"
                [string]$log = "#####PROBLEM#####"+$date.ToString() +" - CONEXÃO SSH no Switch de IP "+ $ipaddress.ToString() + " NÃO DEU CERTO!"
                Add-Content -Path $pathlog -Value $log
                Start-Sleep -Seconds 5
                cls
                break
                }
$session = Get-SSHSession -Index 0
Write-Host "-----------------------------"

Write-Host "`n"
Write-Host "`n"
Write-Host "--------CRIANDO-SHELL-STREAM---------"
$stream = $session.Session.CreateShellStream("Dimi", 1000, 1000, 1000, 1000, 1000)
$streamoutput = $stream.Read()
Clear-Variable streamoutput -Verbose
Start-Sleep -Seconds 1 -Verbose
$stream
Write-Host "-----------------------------"

Write-Host "`n"
Write-Host "`n"
Write-Host "-----------ENTRADA------------"
$stream.Write("en`n")
Start-Sleep -Seconds 1
$streamoutput = $stream.Read()
Write-Host $streamoutput
Clear-Variable streamoutput
Write-Host "------------------------------"

Write-Host "`n"
Write-Host "`n"
Write-Host "--------RUNNING-CONFIG---------"
function01-hp2530 -command "show run"
Write-Host "-------------------------------"

Write-Host "`n"
Write-Host "`n"
Write-Host "---------------CONFIGURA-E-VERIFICA-HORA----------------"
$synctime = function02-synctime
                        
                        if ($synctime -eq 'True')
                        {
                        $date = get-date
                        Write-Host "HORA E DATA SINCRONIZADOS"
                        [string]$log = $date.ToString() +" - Switch de IP "+ $ipaddress.ToString() + " está com hora e data sincronizados!"
                        Add-Content -Path $pathlog -Value $log
                        }
                            else
                            {
                            Write-Host "HORA E DATA NAO SINCRONIZADOS, VERIFIQUE!"
                            [string]$log = "#####PROBLEM#####"+$date.ToString()+" - Firmware do Switch de IP "+ $ipaddress.ToString() + " não foi atualizado pois a hora e data estão errados, verifique!"
                            Add-Content -Path $pathlog -Value $log
                            Start-Sleep -Seconds 5
                            cls
                            break
                            }
                            
Write-Host "--------------------------------------------------------"


#-------------------------------------------------------------------------------------
            "`n`n---------DANDO PUSH DOS COMANDOS---------"
            Clear-Variable streamoutput
            Write-Host "$date - ###Switch de IP $ipaddress iniciou o processo de push command###`n`n"
            [string]$log = $date.ToString() +" - Switch de IP "+ $ipaddress.ToString() + " iniciou o processo de push command"
            Add-Content -Path $pathlog -Value $log

            $stream.Write("system-view`n")
            Start-Sleep -Seconds 1
            function01-hp2530 -command "igmp filter-unknown-mcast"
            Start-Sleep -Seconds 10
            Write-Host $streamoutput
                function01-hp2530 -command "save"
                Start-Sleep -Seconds 10    
                Write-Host $streamoutput   
#-------------------------------------FINAL-TEST-------------------------------------            
           $stream.Write("show run`n")
           Start-Sleep -Seconds 10
           $streamoutput = $stream.Read()        
           Write-Host $streamoutput
           $test_validation = $streamoutput.Contains("filter-unknown-mcast")
                        if ($test_validation -ne 'true')
                        {
                        Write-Host "`n`n#####$date - Algo deu errado com a execução do comando no switch de IP $ipaddress !!!#####`n`n"
                        [string]$log = "#####PROBLEM#####"+$date.ToString() +" - Algo deu errado com a execução do comando no switch de IP "+ $ipaddress.ToString() 
                        Add-Content -Path $pathlog -Value $log
                        $final_verification = "n"
                        }
                            else
                            {
                            Write-Host "`n`n#####$date - A execução do comando no switch de IP $ipaddress DEU CERTO!!!`n`n"
                            [string]$log = $date.ToString() +" - A execução do comando no switch de IP "+ $ipaddress.ToString() + " DEU CERTO!!!"
                            Add-Content -Path $pathlog -Value $log
                            Clear-Variable streamoutput
                            }


Write-Host "-----------------------------"
Write-Host "`n"
Write-Host "`n"
Write-Host "--------REMOVENDO SESSAO SSH---------"
Remove-SSHSession -Index 0 -Verbose
Write-Host "-------------------------------------"
                      
#-------------------------------------------------------------------------------------                      

    }
    else {
         write-host $ip.("IPAddress") "Ping failed." -foreground red
         Write-Host "Tentando pingar novamente"
         $cont++
         $date = get-date
         Start-Sleep -Seconds 2
            if ($cont -gt 2)
            {
            [string]$log = "#####PROBLEM#####"+$date.ToString() +" - Switch de IP "+ $ipaddress.ToString() + " não respondeu ao ping, e por isso não pode ser verificado"
            Add-Content -Path $pathlog -Value $log
            }
       }





      
      }
}


# SIG # Begin signature block
# MIIEOgYJKoZIhvcNAQcCoIIEKzCCBCcCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpPoBHVPVcEyXnBGgrkdV3XL/
# 9EegggJEMIICQDCCAa2gAwIBAgIQVB3qufqZrZpKhWR9rnNo7zAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNzA3MTQxMjEyMTdaFw0zOTEyMzEyMzU5NTlaMCExHzAdBgNVBAMTFkRpbWl0
# cmkgUG93ZXJTaGVsbCBDU0MwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALXt
# 21SuIH+ODd1F82+fp45oUFGw2R+NzvdfKyao44xABoxtqkv2uquqRbo1Fi+jsd80
# HzcHO3BOPUZJsFtuADZhQZmhV3oMjWoSaGmWgOaERkYb01AJo311LNMd9duwQjqz
# XY6VtOj4SnqwB9xY6VmUVvpsNdIPBsD9pziX3sdFAgMBAAGjdjB0MBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMF0GA1UdAQRWMFSAEGPPo05+xF03EpNY4Co5jEqhLjAsMSow
# KAYDVQQDEyFQb3dlclNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3SCEHt8lZC+
# seeASfvlb8W6Jc4wCQYFKw4DAh0FAAOBgQApVBuK8PfCTBdPMTgv+o/sq0rVCc9Z
# ozaUkfUW91B8APzCL52cHmLN8GQsnm7Up2l0iD9ul3EqaAPrLaoxoeYdCrea5Boi
# TA+zYaS4Cp2oDL/SWtQH4TNpEbQEl+4a5Rn7iq8RqsB1m7EsG80Q1aDrzVyeLhYK
# 8IT6eqWnoiqR6TGCAWAwggFcAgEBMEAwLDEqMCgGA1UEAxMhUG93ZXJTaGVsbCBM
# b2NhbCBDZXJ0aWZpY2F0ZSBSb290AhBUHeq5+pmtmkqFZH2uc2jvMAkGBSsOAwIa
# BQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgor
# BgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3
# DQEJBDEWBBSrKy8iIlBXHKyJ34AgEyph6r7cVTANBgkqhkiG9w0BAQEFAASBgDOL
# ohv9nui0Oc3M+d9rjTWZAn5rG6eZ28w07lZ76PjxWMpSn4amF5dfIPP9g2LV6Nym
# 68NTvqIb51RMsxcpxtw9ffScNR2KFiINIc+2JbhTxxZLad3iEUHJDHnyg7l+dnNA
# bsZD5Bjd9m8rXJ8lzD9CXVBGXv3cUtMSllSx1qAo
# SIG # End signature block
