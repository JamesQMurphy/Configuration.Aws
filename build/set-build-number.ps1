<#

NuGet version
Sets the build number based on the following rules, where N = 1, 2, 3

1.  If the build is for a releases/vMajor.Minor[-beta] branch, set it to vMajor.Minor[-beta][.N]
2.  If the build is for a releases/* branch, throw an error
3.  If the build is for a pull request, set it to pr-<pullrequestnumber>[.N]
4.  Otherwise, set it to 0.0.0-<branchname>[.N] (including the main branch)

See https://www.jamesqmurphy.com/blog/2019/08/build-numbering to learn more.


Also sets the package version number
 
#>

. "$PSScriptRoot/common-functions.ps1"

$regexForReleasesBranchPattern = $env:JQM_RELEASESBRANCHPATTERN.Replace('/','\/').Replace('-','\-')
Write-Output "JQM.ReleasesBranchPattern: $regexForReleasesBranchPattern"

function Get-BuildNumberBase ($sourceBranch, $branchName, $versionMajor, $versionMinor) {

    $baseBuildNumber = "0.0.0-$branchName-$versionMajor.$versionMinor"
    $foundError = ''

    switch -regex ($sourceBranch) {
    

        '^refs\/heads\/releases\/' {
            $foundError = "Invalid branch name $sourceBranch"
        }

        '^refs\/heads\/releases\/\d+\.\d+' {
            $foundError = "Invalid branch name $sourceBranch (missing a 'v' before the version)"
        }
    
        "^$($regexForReleasesBranchPattern)(\d+)\.(\d+)(-.+)?" {
            if (($Matches[1] -ne $versionMajor) -or ($Matches[2] -ne $versionMinor)) {
                throw "Version of branch $branchName ($($Matches[1]).$($Matches[2])) does not match VersionMajor/VersionMinor ($versionMajor.$versionMinor)"
            }
            else {
                $foundError = $null
                $baseBuildNumber = "$($Matches[1]).$($Matches[2])$($Matches[3])"
            }
        }

        '^refs/pull/(\d+)/merge' {
            $baseBuildNumber = "pr-$($Matches[1])"
        }

        default {
            $baseBuildNumber = "0.0.0-$branchName-$versionMajor.$versionMinor"
        }
    }

    if ($foundError) { throw $foundError }
    return $baseBuildNumber
}


$baseBuildNumber = Get-BuildNumberBase $env:BUILD_SOURCEBRANCH $env:BUILD_SOURCEBRANCHNAME $env:VERSIONMAJOR $env:VERSIONMINOR
Write-Output "Base build number: $baseBuildNumber"

#Determine value of N to tack on the end
$N = 0

# Retrieve builds for this definition that match the pattern
$previousBuildNumbers = Invoke-AzureDevOpsWebApi 'build/builds' -Version '5.0' -QueryString "definitions=$($env:SYSTEM_DEFINITIONID)&buildNumber=$baseBuildNumber*" | Select-Object -ExpandProperty Value | Select-Object -ExpandProperty buildNumber

# Find the highest build number in the previous builds
if (($null -ne $previousBuildNumbers) -and (@($previousBuildNumbers).Count -gt 0)) {
    
    Write-Output "Previous builds found that match $($baseBuildNumber): "
    @($previousBuildNumbers) | ForEach-Object {
        Write-Output " $_"
        if ($_ -eq $baseBuildNumber) {
            $N = 1
        }
    }

    @($previousBuildNumbers) | Where-Object {$_ -match "^$baseBuildNumber\.\d+`$" } | ForEach-Object {
        $split = $_ -split '\.'
        $previousN = [Int32]::Parse($split[($split.Length - 1)])
        if ($previousN -ge $N) {
            $N = $previousN + 1
            Write-Output "Setting `$N to $N because of previous build number $_"
        }
    }
}
else {
    Write-Output "No previous builds found beginning with $baseBuildNumber"
}

# Set actual build number        
if ($N -eq 0) {
    $newBuildNumber = $baseBuildNumber
}
else {
    $newBuildNumber = "$baseBuildNumber.$N"
}
Write-Output "`$N=$N; setting build number to $newBuildNumber"

Write-AzureDevOpsLoggingCommand -Area build -Action updatebuildnumber -Message $newBuildNumber


# Set package version number
if ($env:BUILD_SOURCEBRANCH -like 'refs/pull/*') {
    $packageVersion = "0.0.0-$($newBuildNumber)"
}
else {
    $packageVersion = $newBuildNumber
}
Write-Output "Setting Package.Version=$packageVersion"
Write-AzureDevOpsLoggingCommand -Area task -Action setvariable -Properties @{variable='Package.Version'} -Message $packageVersion

