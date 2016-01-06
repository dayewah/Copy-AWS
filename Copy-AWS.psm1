
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
        [switch]$Recurse
    
    )

    begin{
        $pscp="C:\Program Files (x86)\PuTTY\pscp.exe"
        $root=Get-Root -FolderName .pscp    
        if($root)
        { 
            $info=(Get-Content -Path "$root\pscp_info.txt") -join "`r`n" |ConvertFrom-StringData

            $KeyFile=if(!$KeyFile){$info.keyfile}else{ (Resolve-Path $KeyFile).Path}
            $KeyFile=if(!(Test-Path $KeyFile)){"`"$root\$($info.keyfile)`""}else{$KeyFile}
            $KeyFile= if($info.keyfile){"-i `"$root\$($info.keyfile)`""}

            $Username=if(!$Username){$info.username}else{$Username}

            $Password=if(!$Password){$info.password}else{$Password}
            $Password=if($Password){"-pw $($Password)"}

            $Address=if(!$Address){$info.address}else{$Address}

                       
        }            
        
        Write-Verbose "pscp: $pscp"
        Write-Verbose "root: $root"
        Write-Verbose "keyfile: $keyfile"
        Write-Verbose "username: $Username"
        Write-Verbose "password: $Password"
        Write-Verbose "address: $Address"

        if($Recurse){$r="-r"}
    }

    process {
        if($info)
        {
            foreach($path in $source)
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
            
                Write-Verbose $command            
                #Invoke-Expression $command
            }
        }

    }

    end{

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
        Write-Host "Path: $CurrentPath is the drive root: $driveRoot"
        Write-Host "root path $FolderName not found."
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