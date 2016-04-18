#Set-PSDebug -Trace 2
$baseDir = "C:\generate_windows_images"
$buildArea = Join-Path -Path "$baseDir" -ChildPath "build_area"
$logDir = Join-Path -Path "$buildArea" -ChildPath "logs"
$woitDir = Join-Path -Path "$buildArea" -ChildPath "devel-woit-$env:BUILD_NUMBER"
$scriptDir = Join-Path -Path "$buildArea" -ChildPath "devel-ws2016-jenkins-$env:BUILD_NUMBER"
$logName = (Get-Date).ToString('ddMMyyy') + '-' + "$env:BUILD_NUMBER" + '-devel.txt'
$logPath = Join-Path -Path "$logDir" -ChildPath "$logName"
$imageName = (Get-Date).ToString('ddMMyyy') + '-' + "$env:BUILD_NUMBER" + '-devel-dd'
$isoDir = Join-Path -Path "$baseDir" -ChildPath "generated_images"
$targetPath = Join-Path -Path "$isoDir" -ChildPath "$imageName"
$virtPath = Join-Path -Path "$baseDir" -ChildPath "optional_images\virtio-win-0.1.102.iso"

try {
    If (Get-Module WinImageBuilder) {
        Remove-Module WinImageBuilder
    }
    ls $woitDir
    Import-Module "$woitDir\WinImageBuilder.psm1"

    #This is the content of your Windows ISO
    $driveLetter = (Mount-DiskImage $finalISO -PassThru | Get-Volume).DriveLetter 
    $wimFilePath = "${driveLetter}:\sources\install.wim"

    # Check what images are supported in this Windows ISO
    $images = Get-WimFileImagesInfo -WimFilePath $wimFilePath

    Write-Host "Choosing the imageEdition"
    # Choosing the type of image. Does not apply on Windows Server 2008
    If ($env:imageEdition -eq 'CORE') {
        $image = $images[0]
    } else {
        $image = $images[1]
    }

    If ($env:runSysprep -eq 'YES') {
        [boolean]$runSysprep = $true
    } else {
        [boolean]$runSysprep = $false 
    }

    If ($env:installUpdates -eq 'YES') {
        [boolean]$installUpdates = $true
    } else {
        [boolean]$installUpdates = $false
    }

    If ($env:purgeUpdates -eq 'YES') {
        [boolean]$purgeUpdates = $true
    } else {
        [boolean]$purgeUpdates = $false
    }
    Write-Host "purgeUpdates are set to $purgeUpdates"

    If ($env:persistDrivers -eq 'YES') {
        [boolean]$persistDrivers = $true
    } else {
        [boolean]$persistDrivers = $false
    }

    If ($env:force -eq 'YES') {
        [boolean]$force = $true
    } else {
        [boolean]$force = $false
    }

    #If ([boolean]$purgeUpdates -eq '$true') {
    #    If ([boolean]$installUpdates -eq '$false') {
    #        Write-Warning "You have purgeUpdates set to yes but installUpdates is set to no."
    #        Write-Warning "Will not purge the updates"
    #        [boolean]$purgeUpdates = $false
    #    }
    #}
    Write-Host "purgeUpdates are set to $purgeUpdates"

    If ($env:persistDriver -eq 'YES') {
        $persistDriver = $true
    } else {
        $persistDriver = $false
    }

    If ($env:installHyperV -eq 'NO') {
        $ExtraFeatures = @()
    }

    Write-Host "Writing all the environment variables"
    Get-ChildItem Env:
    Write-Host "Finished writing all environment variables"
    
    Write-Host "Writing all the variables"
    Get-Variable | Out-String
    Write-Host "Finished writing all variables"

   [uint64]$sizeBytes = $env:sizeBytes
   $sizeBytes = $sizeBytes * 1GB 
   [uint64]$memory = $env:memory
   $memory = $memory * 1GB
   [uint64]$cpuCores = $env:CpuCores

   $env:imageType = $env:imageType.ToUpper()

    Write-Host "Starting the image generation..."
    New-WindowsOnlineImage -Type $env:imageType -WimFilePath $wimFilePath -ImageName $image.ImageName -WindowsImagePath $targetPath -SizeBytes $sizeBytes -Memory $memory -CpuCores $cpuCores -DiskLayout $env:diskLayout -RunSysprep:$runSysprep -PurgeUpdates:$purgeUpdates -InstallUpdates:$installUpdates -Force:$force -PersistDriverInstall:$persistDriver -SwitchName $env:switchName -VirtIOISOPath $env:virtPath -ProductKey $env:productKey

    Write-Host "Finished the image generation."
} catch {
    Write-Host "Image generation has failed."
    Write-Host $_
} finally {
    Write-Host "Dismounting the iso: $finalISO"
    Dismount-DiskImage -DevicePath $driveLetter
}
