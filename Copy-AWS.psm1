
function Copy-AWS
{
    param(
        [Parameter(
            Position=0,
            Mandatory=$True, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        [string[]]$Source, 

        [Parameter(
            Position=1,
            Mandatory=$True)]
        [string]$Destination,

        [Parameter(Mandatory=$False)]
        [switch]$Recurse
    
    )

    begin{
        $pscp="C:\Program Files (x86)\PuTTY\pscp.exe"
        $root=Get-Root -Path (pwd)        
        if($root)
        { 
            $aws_info=Get-Content -Path "$root\aws_info.txt"|ConvertFrom-StringData
            $keypath= "$root\$($aws_info.keyfile)"
            $host=$aws_info.dns
        }
        

        if($Recurse){$r="-r"}
    }

    process {
        if($aws_info)
        {
            foreach($path in $source)
            {
                $name=$path -split "[\\/]"| Select-Object -Last 1

                if(!(Test-Path -Path $Destination) -and ($Destination -match "/"))
                {
                    Write-Verbose "remote destination"                
                    $command="& `"$pscp`" $r -i $keypath $path ec2-user@$host:$destination"
                }
                else
                {
                    Write-Verbose "local destination"
                    $command="& `"$pscp`" $r -i $keypath ec2-user@$host:$path $destination"
                }
            
                Write-Verbose $command            
                Invoke-Expression $command
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


function Get-Root([string] $path)
{
    Write-Verbose $path   

    if(Get-ChildItem $path\*.aws)
    {
        return "$path\.aws"
    }

    $root=[System.IO.Directory]::GetDirectoryRoot($path)
    if($path -eq $root)
    {
        Write-Host "Path name: $path is equal to root name: $root"
        Write-Host "root path .aws not found."
        return 
    }
    
    $path=([System.IO.Directory]::GetParent(($path))).FullName
    Get-Root $path
    
}

Write-Host "Imported Copy-AWS"
Export-ModuleMember -Function Copy-AWS