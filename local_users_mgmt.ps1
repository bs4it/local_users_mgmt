# variables:

$IgnoredUsers = Get-Content -Path ".\ignored_users.txt"
$LoopServers = Get-Content -Path ".\servers_list.txt"

function ListUsers {
    $out = Get-LocalUser
    Write-Host "Quering users..."
    Start-Sleep -Seconds 1
    Clear-Host
    Write-Host -ForegroundColor White -NoNewline "======================== "
    Write-Host -ForegroundColor Green -NoNewline "Showing local users on $env:computername"
    Write-Host -ForegroundColor White " ========================"
    Get-LocalUser | Select-Object Enabled,Name,Fullname,Description | Format-Table -HideTableHeaders:$false
    Write-Host -ForegroundColor Yellow -NoNewline "Press any key to return to the main menu."
    Read-Host
}

function CreateUser {
    Clear-Host
    Write-Host -ForegroundColor White -NoNewline "====================== "
    Write-Host -ForegroundColor Green -NoNewline "Creating a new local user on all servers"
    Write-Host -ForegroundColor White " ======================"
    Write-Host ""
    Write-Host -ForegroundColor Yellow "Enter the proper information to create a new user."
    Write-Host ""
    Write-Host -ForegroundColor DarkYellow -NoNewline "Username:"
    $NewUsername = Read-Host
    Write-Host -ForegroundColor DarkYellow -NoNewline "Full Name:"
    $NewUserFullName = Read-Host
    Write-Host -ForegroundColor DarkYellow -NoNewline "Description (BS4IT User):"
    $NewUserDescription = Read-Host
    if ( ! $NewUserDescription ) {$NewUserDescription = "BS4IT User"}

    do {
        Write-Host -ForegroundColor DarkYellow -NoNewline "Enter Password (8 chars or more):"
        $NewUserPassword = Read-Host -AsSecureString
        Write-Host -ForegroundColor DarkYellow -NoNewline "Confirm Password:"
        $NewUserPassword1 = Read-Host -AsSecureString
        $pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewUserPassword))
        $pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewUserPassword1))
        if (($pwd1_text -ne $pwd2_text) -or ($pwd1_text.Length -lt 8)) { Write-Host -ForegroundColor Red "Passwords did not match or have less than 8 chars, try again:" }
        }
        while (($pwd1_text -ne $pwd2_text) -or ($pwd1_text.Length -lt 8))
    Write-Host "Passwords matched"
    Write-Host ""
    Write-Host -ForegroundColor Yellow -NoNewline "Proceed creating the user $NewUsername with the above information on all the" $LoopServers.Length "servers? (Y/N):"
    $NewUserConfirmation = Read-Host

    if ($NewUserConfirmation -eq "y") {
        Write-Host ""
        Write-Host -ForegroundColor Green "Starting user creation..."
        $LoopServers | ForEach-Object {
            Write-Host -ForegroundColor White -NoNewline "Creating user"
            Write-Host -ForegroundColor DarkYellow -NoNewline " $NewUsername "
            Write-Host -ForegroundColor White -NoNewline "on"
            Write-Host -ForegroundColor DarkYellow -NoNewline " $_"
            Write-Host -ForegroundColor White -NoNewline "...`t"
            $out = Invoke-Command -Hostname $_ -Command { New-LocalUser $using:NewUsername -Password $using:NewUserPassword -FullName $using:NewUserFullName -Description $using:NewUserDescription -PasswordNeverExpires:$true -AccountNeverExpires:$true | Add-LocalGroupMember -Group "Administrators" }
            #$out = Invoke-Command -Hostname $_ -Command { Get-Host }
            if ($?) {
                Write-Host -ForegroundColor DarkGreen "OK"
            }
        }
        Write-Host -ForegroundColor White ""
        Write-Host -ForegroundColor DarkGreen "Done!"
        Read-Host -Prompt "Press any key to return to the main menu"
    } else {
        Write-Host "No action was taken, returning to main menu."
        Start-Sleep -Seconds 2
    }
}

function ResetUserPassword {
    $LocalUsers = Get-LocalUser | Where-Object { $IgnoredUsers -notcontains $_.name }
    $errmsg = ""
    do {
        Clear-Host
        Write-Host -ForegroundColor White -NoNewline "================ "
        Write-Host -ForegroundColor Green -NoNewline "Select an user to reset its password on all servers"
        Write-Host -ForegroundColor White " ================"
        #Write-Host -ForegroundColor Green "Select an user to be permanentely deleted on all servers"
        $script:ObjIndex = 0
        $LocalUsers | Format-Table -Property @{name="ID";expression={$script:ObjIndex;$script:ObjIndex+=1}},Name,FullName,Description
        Write-Host -ForegroundColor Red "$errmsg"
        Write-Host -ForegroundColor Yellow -NoNewline "Type the ID of the user you want the password reset or R to return to the main menu:"
        $SelectedUser = Read-Host
        if (-Not ($SelectedUser -in 1..$LocalUsers.Count) -or ($SelectedUser -ne "r")){$errmsg = "This value must be within the IDs!"}
    } while (($SelectedUser.Length -eq 0) -or -Not (($SelectedUser -in 1..$LocalUsers.Count) -or ($SelectedUser -eq "r")) )
    #} while (($SelectedUser.Length -eq 0) -or -Not ($SelectedUser -in 1..$LocalUsers.Count) )

    if ($SelectedUser -ne "r") {
        $SelectedUser = $LocalUsers.Item($SelectedUser-1)
        Clear-Host
        Write-Host -ForegroundColor White -NoNewline "================= "
        Write-Host -ForegroundColor Green -NoNewline "This user's password will be reset on all servers"
        Write-Host -ForegroundColor White " ================="
        Write-Host -ForegroundColor White -NoNewline "==================================== "
        Write-Host -BackgroundColor DarkRed -NoNewline "ATTENTION!"
        Write-Host -ForegroundColor White " ===================================="
        Write-Host -ForegroundColor White -NoNewline "Are you really sure you want to reset the password for user "
        Write-Host -ForegroundColor DarkYellow ($SelectedUser.Name+" ("+$SelectedUser.FullName+") ")
        Write-Host -ForegroundColor White "on the following servers?"
        Write-Host ""
        $LoopServers | ForEach-Object { Write-Host -ForegroundColor DarkYellow $_}
        Write-Host ""
        Write-Host -BackgroundColor DarkRed "!!! SOME SERVICES MAY BREAK UPON PASSWORD CHANGING!!!"
        Write-Host -ForegroundColor Yellow -NoNewline "ARE YOU SURE TO RESET PASSWORD FOR THE USER $SelectedUser ? (Y/N):"
        Write-Host ""
        $Confirmation = Read-Host
        if ($Confirmation -eq "Y") {
            $SelectedUserName = $SelectedUser.Name
            do {
                Write-Host -ForegroundColor DarkYellow -NoNewline "Enter New Password (8 chars or more):"
                $NewUserPassword = Read-Host -AsSecureString
                Write-Host -ForegroundColor DarkYellow -NoNewline "Confirm New Password:"
                $NewUserPassword1 = Read-Host -AsSecureString
                $pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewUserPassword))
                $pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewUserPassword1))
                if (($pwd1_text -ne $pwd2_text) -or ($pwd1_text.Length -lt 8)) { Write-Host -ForegroundColor Red "Passwords did not match or have less than 8 chars, try again:" }
            }
            while (($pwd1_text -ne $pwd2_text) -or ($pwd1_text.Length -lt 8))
            Write-Host "Passwords matched"
            Write-Host ""
            Write-Host -ForegroundColor Green "Starting user password reset..."
            $LoopServers | ForEach-Object {
                Write-Host -ForegroundColor White -NoNewline "Resetting password for user"
                Write-Host -ForegroundColor DarkYellow -NoNewline " $SelectedUserName "
                Write-Host -ForegroundColor White -NoNewline "on"
                Write-Host -ForegroundColor DarkYellow -NoNewline " $_"
                Write-Host -ForegroundColor White -NoNewline "...`t"
                $out = Invoke-Command -Hostname $_ -Command { Get-LocalUser -Name $using:SelectedUserName | Set-LocalUser -Password $using:NewUserPassword }
                #$out = Invoke-Command -Hostname $_ -Command { Get-Host }
                if ($?) {
                    Write-Host -ForegroundColor DarkGreen "OK"
                }
            }
            Write-Host -ForegroundColor White ""
            Write-Host -ForegroundColor DarkGreen "Done!"
            Read-Host -Prompt "Press any key to return to the main menu"
        } else {
            Write-Host "No action was taken, returning to main menu."
            Start-Sleep -Seconds 2
        }
    } else {
        Write-Host -ForegroundColor White "Returning to main menu."
        Start-Sleep -Milliseconds 750
    }    
}

function DeleteUser {
    $LocalUsers = Get-LocalUser | Where-Object { $IgnoredUsers -notcontains $_.name }
    $errmsg = ""
    do {
        Clear-Host
        Write-Host -ForegroundColor White -NoNewline "============= "
        Write-Host -ForegroundColor Green -NoNewline "Select an user to be permanentely deleted from all servers"
        Write-Host -ForegroundColor White " ============="
        #Write-Host -ForegroundColor Green "Select an user to be permanentely deleted on all servers"
        $script:ObjIndex = 0
        $LocalUsers | Format-Table -Property @{name="ID";expression={$script:ObjIndex;$script:ObjIndex+=1}},Name,FullName,Description
        Write-Host -ForegroundColor Red "$errmsg"
        Write-Host -ForegroundColor Yellow -NoNewline "Type the ID of the user you want to delete or R to return to the main menu:"
        $SelectedUser = Read-Host
        if (-Not ($SelectedUser -in 1..$LocalUsers.Count) -or ($SelectedUser -ne "r")){$errmsg = "This value must be within the IDs!"}
    } while (($SelectedUser.Length -eq 0) -or -Not (($SelectedUser -in 1..$LocalUsers.Count) -or ($SelectedUser -eq "r")) )
    #} while (($SelectedUser.Length -eq 0) -or -Not ($SelectedUser -in 1..$LocalUsers.Count) )

    if ($SelectedUser -ne "r") {
        $SelectedUser = $LocalUsers.Item($SelectedUser-1)
        Clear-Host
        Write-Host -ForegroundColor White -NoNewline "========== "
        Write-Host -ForegroundColor Green -NoNewline "The selected user will be permanentely deleted from all servers"
        Write-Host -ForegroundColor White " =========="
        Write-Host -ForegroundColor White -NoNewline "==================================== "
        Write-Host -BackgroundColor DarkRed -NoNewline "ATTENTION!"
        Write-Host -ForegroundColor White " ===================================="
        Write-Host -ForegroundColor White -NoNewline "Are you really sure you want to permanentely remove the user "
        Write-Host -ForegroundColor DarkYellow ($SelectedUser.Name+" ("+$SelectedUser.FullName+") ")
        Write-Host -ForegroundColor White "from the following servers?"
        Write-Host ""
        $LoopServers | ForEach-Object { Write-Host -ForegroundColor DarkYellow $_}
        Write-Host ""
        Write-Host -BackgroundColor DarkRed "!!! THIS IS IRREVERSIBLE !!!"
        Write-Host -ForegroundColor Yellow -NoNewline "ARE YOU SURE TO DELETE THE USER $SelectedUser ? (Y/N):"
        $Confirmation = Read-Host
        if ($Confirmation -eq "Y") {
            $SelectedUserName = $SelectedUser.Name
            Write-Host -ForegroundColor Green "Starting user deletion..."
            $LoopServers | ForEach-Object {
                Write-Host -ForegroundColor White -NoNewline "Deleting user"
                Write-Host -ForegroundColor DarkYellow -NoNewline " $SelectedUserName "
                Write-Host -ForegroundColor White -NoNewline "from"
                Write-Host -ForegroundColor DarkYellow -NoNewline " $_"
                Write-Host -ForegroundColor White -NoNewline "...`t"
                $out = Invoke-Command -Hostname $_ -Command { Remove-LocalUser -Confirm:$false -Name $using:SelectedUserName }
                #$out = Invoke-Command -Hostname $_ -Command { Get-Host }
                if ($?) {
                    Write-Host -ForegroundColor DarkGreen "OK"
                }
            }
            Write-Host -ForegroundColor White ""
            Write-Host -ForegroundColor DarkGreen "Done!"
            Read-Host -Prompt "Press any key to return to the main menu"
        } else {
            Write-Host "No action was taken, returning to main menu."
            Start-Sleep -Seconds 2
        }
    } else {
        Write-Host -ForegroundColor White "Returning to main menu."
        Start-Sleep -Milliseconds 750
    }    
}



function CreateUsersOnNewServer {
    $LocalUsers = Get-LocalUser | Where-Object { $IgnoredUsers -notcontains $_.name }
    $errmsg = ""
    do {
        Clear-Host
        Write-Host -ForegroundColor White -NoNewline "=========== "
        Write-Host -ForegroundColor Green -NoNewline "Type the hostname or IP of a new server to create users on it"
        Write-Host -ForegroundColor White " ==========="
        Write-Host "To return to previous menu, type 'r' and hit ENTER"
        Write-Host -ForegroundColor Yellow "The server must have POSH Core and SSH set accordingly."
        $NewServer = (Read-Host -Prompt "Server").ToUpper()
    } while (($NewServer.Length -eq 0))
    #} while (($SelectedUser.Length -eq 0) -or -Not ($SelectedUser -in 1..$LocalUsers.Count) )

    if ($NewServer -ne "r") {
        #Testar SSH
        Write-Host -NoNewline "Trying to connect to $NewServer ..."
        $ssh_test = Invoke-Command -Hostname $NewServer -Command { Get-Host }
        if ($ssh_test -ne $null) {
            Write-Host -ForegroundColor Green " OK"
            Write-Host ""
            Write-Host -NoNewline "The Server "
            Write-Host -NoNewline -ForegroundColor Cyan $ssh_test.PSComputerName.ToString()
            Write-Host -NoNewline " is running PowerShell Version "
            Write-Host -ForegroundColor Cyan $ssh_test.Version.ToString()
            Write-Host ""
            Write-Host -ForegroundColor Yellow "The following users will be created on $NewServer. If any of these already exist they will not be affected."
            $script:ObjIndex = 0
            $LocalUsers | Format-Table -Property @{name="ID";expression={$script:ObjIndex;$script:ObjIndex+=1}},Name,FullName,Description            
            Write-Host -ForegroundColor Yellow -NoNewline "DO YOU WANT TO GO AHEAD ? (Y/N):"
            $Confirmation = Read-Host
            if ($Confirmation -eq "Y") {
                # senha
                do {
                    Write-Host -ForegroundColor DarkYellow -NoNewline "Enter New Password (8 chars or more):"
                    $NewUserPassword = Read-Host -AsSecureString
                    Write-Host -ForegroundColor DarkYellow -NoNewline "Confirm New Password:"
                    $NewUserPassword1 = Read-Host -AsSecureString
                    $pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewUserPassword))
                    $pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewUserPassword1))
                    if (($pwd1_text -ne $pwd2_text) -or ($pwd1_text.Length -lt 8)) { Write-Host -ForegroundColor Red "Passwords did not match or have less than 8 chars, try again:" }
                }
                while (($pwd1_text -ne $pwd2_text) -or ($pwd1_text.Length -lt 8))
                Write-Host "Passwords matched"
                Start-Sleep -Seconds 1

                Write-Host -ForegroundColor Yellow "Starting users creation on $NewServer"

                $LocalUsers | ForEach-Object {
                    $NewUsername = $_.Name
                    $NewUserFullName = $_.FullName
                    $NewUserDescription = $_.Description
                    Write-Host -NoNewline -ForegroundColor White "Creating user "
                    Write-Host -NoNewline -ForegroundColor Cyan $NewUsername
                    Write-Host -NoNewline -ForegroundColor White " on server "
                    Write-Host -ForegroundColor Cyan $NewServer
                    $NewUser = Invoke-Command -Hostname $NewServer -Command { New-LocalUser $using:NewUsername -Password $using:NewUserPassword -FullName $using:NewUserFullName -Description $using:NewUserDescription -PasswordNeverExpires:$true -AccountNeverExpires:$true | Add-LocalGroupMember -Group "Administrators" }
                }
                Write-Host ""
                Write-Host "Operation completed."
                Write-Host -NoNewline -ForegroundColor Red "IMPORTANT NOTE: "
                Write-Host -ForegroundColor Yellow "Please be sure to include $NewServer to the 'servers_list.txt' file."
                Write-Host ""
                Read-Host -Prompt "Press ENTER to return to main menu"
            }

        }
        else {
            Write-Host ""
            Write-Host -ForegroundColor Yellow "SSH Connecion failed. Check hostname or IP and if the server is prepared (SSHD + POSH)"
            Write-Host ""
            Read-Host -Prompt "Press ENTER to return to main menu"
        }
    } 
    Write-Host -ForegroundColor White "Returning to main menu."
    Start-Sleep -Milliseconds 750  
}


function Show-Menu
{
    param (
        [string]$Title = 'My Menu'
    )
    Clear-Host
    Write-Host -ForegroundColor White -NoNewline "================ "
    Write-Host -ForegroundColor Green -NoNewline "$Title"
    Write-Host -ForegroundColor White " ================"
    Write-Host ""
    Write-Host "1: List local users on current server."
    Write-Host "2: Create local user on all servers."
    Write-Host "3: Reset user password on all servers."
    Write-Host "4: Delete local user from all servers."
    Write-Host "5: Create local users on a new server."
    Write-Host "Q: Press 'Q' to quit."
}

do
 {
     Show-Menu -Title "Welcome to BS4IT User management Powershell Scripts"
     Write-Host ""
     Write-Host -ForegroundColor Yellow -NoNewline "Please make a selection:"
     $selection = Read-Host
     switch ($selection)
     {
         '1' {
            ListUsers
         }
         '2' {
            CreateUser
         }
         '3' {
            ResetUserPassword
         }
         '4' {
            DeleteUser
         }
         '5' {
            CreateUsersOnNewServer
         }
     }
    #  pause
 }
 until ($selection -eq 'q')




#  $LocalUsers = Get-LocalUser | Where { $IgnoredUsers -notcontains $_.name }
#  $errmsg = ""
#  do {
#      Clear-Host
#      Write-Host -ForegroundColor Green "Select an user to be deleted on all servers"
#      Write-Host -ForegroundColor Red "$errmsg"
#      $script:ObjIndex = 0
#      $LocalUsers | Format-Table -Property @{name="ID";expression={$script:ObjIndex;$script:ObjIndex+=1}},Name,FullName,Description
#      $SelectedUser = Read-Host -Prompt "Type the ID of desired server"
#      if (-Not ($SelectedUser -in 1..$LocalUsers.Count)){$errmsg = "This value must be within the IDs!"}
 
#  } while (($SelectedUser.Length -eq 0) -or -Not ($SelectedUser -in 1..$LocalUsers.Count))
 
#  $SelectedUser = $LocalUsers.Item($SelectedUser-1)

 
 
 
 
 
 
#  New-LocalUser "sa.t100xxxx" -Password ( ConvertTo-SecureString "S3cUr3@PWdbs4!T)" -AsPlainText -Force ) -FullName "Teste Teste Teste" -Description "BS4IT User" -PasswordNeverExpires:$true -AccountNeverExpires:$true | Add-LocalGroupMember -Group "Administrators"

