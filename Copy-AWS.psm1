﻿
function Copy-AWS
{
    param(
        [Parameter(Position=0,
        Mandatory=$True, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        [string[]]$Source, 

        [Parameter(Position=1,
        Mandatory=$True)]
        [string]$Destination,

        [Parameter(Mandatory=$False)]
        [string]$Username,

        [Parameter(Mandatory=$False)]
        [string]$KeyFile,

        [Parameter(Mandatory=$False)]
        [string]$Password,

        [Parameter(Mandatory=$False)]
        [string]$Address,

        [Parameter(Mandatory=$False)]
        [switch]$Recurse,
        
        [Parameter(Mandatory=$False)]
        [switch]$Persist,
        
        [Parameter(Mandatory=$False)]
        [switch]$WhatIf
    
    )

    begin{
        $pscp="C:\Program Files (x86)\PuTTY\pscp.exe"
        $root=Get-Root -FolderName .pscp    
        if($root)
        { 
            $info=(Get-Content -Path "$root\pscp_info.txt") -join "`r`n" |ConvertFrom-StringData

            if(!$KeyFile)
            {
                if($info.keyfile){$KeyFile="$root\$($info.keyfile)"}
            }
            else
            {
                $KeyFile=(Resolve-Path $KeyFile).Path
            }
            

            $Username=if(!$Username){$info.username}else{$Username}

            $Password=if(!$Password){$info.password}else{$Password}

            $Address=if(!$Address){$info.address}else{$Address}
        }            
        
        $KeyFile= if($KeyFile){"-i  `"$KeyFile`""}
        $Password=if($Password){"-pw $($Password)"}
        
        
        Write-Verbose "pscp: $pscp"
        Write-Verbose "root: $root"
        Write-Verbose "username: $Username"
        Write-Verbose "address: $Address"
        Write-Verbose "keyfile: $KeyFile"
        Write-Verbose "password: $Password"
        
        $CanRun=$source -and $destination -and $Username -and $Address
        if($Recurse){$r="-r"}
    }

    process {
        if($CanRun)
        {
            foreach($path in $Source)
            {
                $name=$path -split "[\\/]"| Select-Object -Last 1

                if(!(Test-Path -Path $Destination) -and ($Destination -match "/"))
                {
                    Write-Verbose "remote destination"                
                    $command="& `"$pscp`" $r $keyfile $password $path $username@$($address):$destination"
                }
                else
                {
                    Write-Verbose "local destination"
                    $command="& `"$pscp`" $r $keyfile $password $username@$($address):$path $destination"
                }
                
                if($WhatIf)
                {
                    Write-Host "Executes: $command"            
                }
                else
                {
                    Write-Verbose $command            
                    Invoke-Expression $command
                }
            }
        }
        else
        {
            Write-Host "Missing Variable(s):"  
            Write-Host "username: $Username"
            Write-Host "address: $Address"  
        }

    }

    end{
        if($CanRun -and $Persist)
        {
            #implement logic to write out variables to .pscp file
            New-Item -Path .pscp -ItemType dir -Force
            
            if($Password){$Password=$Password.Replace("-pw ","")}
            
            if($KeyFile)
            {
                $KeyFile=$KeyFile.Replace("-i  ","")
                Copy-Item -Path $KeyFile -Destination .pscp 
                $KeyFile=(Get-ChildItem $KeyFile).Name
            }
            
            $file=@"
username=$Username
address=$Address            
keyfile=$KeyFile
password=$Password
"@
            
            New-Item -Path .pscp\pscp_info.txt -ItemType file -Value $file -Force
        }
    }

<#
.SYNOPSIS 
Copies files to and from a remote aws server.

.DESCRIPTION
Copies files to and from a remote aws server using the putty tool pscp.exe. The script determines whether the source is local or remote based on the format of the path string. It also supports wildcards in the source string.

.PARAMETER Source
Specifies the source file or directory name.

.PARAMETER Destination
Specifies the destination file or directory.

.PARAMETER Recurse
Switch to specify a recursive copy from the source directory.


.EXAMPLE
C:\PS> Copy-Aws -Source .\test.txt -Destination /home/ec2-user

Copy a single local file to an aws directory

.EXAMPLE
C:\PS> Copy-Aws -Source /home/ec2-user/*.txt -Destination .

Copy all .txt files in a remote folder from aws to the current directory

.EXAMPLE
C:\PS> Copy-Aws -Source /home/ec2-user/test -Destination . -Recurse

Copy a remote folder from aws to the current directory

.EXAMPLE
C:\PS> dir *.txt| Copy-Aws -Destination /home/ec2-user

Copy files from the pipeline to a directory on the remote server

.LINK
http://the.earth.li/~sgtatham/putty/0.60/htmldoc/Chapter5.html

#>    
}


function Get-Root
{
    param(        
        [Parameter(Position=0,
        Mandatory=$True)]
        [string]$FolderName,
        
        [Parameter(
        Mandatory=$False)]
        [string]$CurrentPath="."
    )
    
    $CurrentPath=Resolve-Path $CurrentPath
    Write-Verbose "Current path is: $CurrentPath"   

    if(Test-Path $CurrentPath\$FolderName)
    {
        return "$CurrentPath\$FolderName"
    }

    $driveRoot=[System.IO.Directory]::GetDirectoryRoot($CurrentPath)
    if($CurrentPath -eq $driveRoot)
    {
        Write-Verbose "Path: $CurrentPath is the drive root: $driveRoot"
        Write-Verbose "root path $FolderName not found."
        return 
    }
    
    $CurrentPath=([System.IO.Directory]::GetParent(($CurrentPath))).FullName
    Write-Verbose "Change current to parent: $CurrentPath"
    Get-Root -FolderName $FolderName -CurrentPath $CurrentPath
<#
.SYNOPSIS 
Gets the path to a specified folder in the parent hierarchy of the current path.
#>    
}

Write-Host "Imported Copy-AWS"
Export-ModuleMember -Function Copy-AWS