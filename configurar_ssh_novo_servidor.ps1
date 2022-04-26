## VARIAVEIS

$ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLVZXhqGtKjoRGT2nNlOyJjkr15LVk2hFBKGExtPRdxtc4jaXHZCIZRCXJxeZdsDQV5frxgnMNFvUdb7rUWWlk697dbnWiPjAW4RhWrI10RDhY1w6Zc6noWgg3275v4bOZ3u/e6/OsSp/GIzQcNH7NKNxzj3QnbWG0MGqy5fOPTvwpREHddFwjx4z7D06LcU2SIZoEaQJt3RTmI/whPELSAfFY8RxnO85v+7xiKgBTjK10zHesj3iUaXhzfI0vjFJzFVp6KufcvyluAHq0Q5ssCu8tdwhPx2L/iDvNVudZr8ZkC90aNrnUFbkCXgsHDCPh/zpHNsYFcWE50UF6n3Mv sa.t1005627@SPDWVIFR012"
$ssh_keys_file = "C:\ProgramData\ssh\administrators_authorized_keys2"

#######################################################################################
Write-Host -ForegroundColor Yellow "ATENCAO: este script só deve ser executado em máquinas que ainda nao tenham o SSHD configurado. Na dúvida, NÃO PROSSIGA!"
$Confirmation = Read-Host -Prompt "Quer mesmo prosseguir? (S/N)"
if ( $Confirmation -ne "S") {
    Write-Host "Saindo.."
    exit 0
}
else {
    Write-Host -ForegroundColor Yellow "Atualizando GPOs"
    gpupdate /force
    Write-Host -ForegroundColor Yellow "Adicionando SSHD"
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host -ForegroundColor Yellow "Configurando inicio automático do SSHD"
    get-service sshd | Set-Service -StartupType Automatic
    Write-Host -ForegroundColor Yellow "Ajustando sshd_config..."
    $filePath = "C:\ProgramData\ssh\sshd_config"
    $textToAdd = "Subsystem	powershell	c:/progra~1/powershell/7/pwsh.exe -sshs -NoLogo -NoProfile"
    $lineNumber = 77
    $fileContent = Get-Content $filePath
    $fileContent[$lineNumber-1] = $textToAdd
    $fileContent | Set-Content $filePath
    Write-Host -ForegroundColor Yellow "Criando arquivo de chaves autorizadas"
    $ssh_key | Out-File $ssh_keys_file
    Write-Host -ForegroundColor Yellow "Ajustando permissoes do arquivo de chaves autorizadas"
    $acl = Get-Acl $ssh_keys_file
    $acl.SetAccessRuleProtection($true, $false)
    $administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
    $systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
    $acl.SetAccessRule($administratorsRule)
    $acl.SetAccessRule($systemRule)
    $acl | Set-Acl
    Write-Host -ForegroundColor Yellow "Iniciando SSHD"
    Start-Service sshd
    Write-Host -ForegroundColor Yellow "Exibindo status do SSHD"
    Get-Service sshd
    Write-Host ""
    Write-Host -ForegroundColor Yellow "Feito."
}
