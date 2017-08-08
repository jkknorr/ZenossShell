#
# Adapted from Invoke-JiraMethod.Tests.ps1, part of AtlassianPS/PSJira
# AtlasianPS/PSJira is maintained by Joshua T.
#
# PSScriptAnalyzer - ignore creation of a SecureString using plain text for the contents of this script file
# https://replicajunction.github.io/2016/09/19/suppressing-psscriptanalyzer-in-pester/
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

. $PSScriptRoot\Shared.ps1
#Import-Module .\ZenossShell\ZenossShell.psm1

InModuleScope ZenossShell {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1
    #Import-Module .\ZenossShell\ZenossShell.psm1

    #$validMethods = @('Get','Post','Put','Delete')  
    $validMethods = @('Post') # Zenoss API only ever wants POSTs

    Describe "Invoke-ZenossAPI" {
        ## Helper functions
        #$ShowMockData = $true
        if ($ShowDebugText)
        {
            Mock "Write-Debug" {
                Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
            }
        }
        function defParam($command, $name)
        {
            It "Has a -$name parameter" {
                $command.Parameters.Item($name) | Should Not BeNullOrEmpty
            }
        }
        function ShowMockInfo($functionName, [String[]] $params) {
            if ($ShowMockData)
            {
                Write-Host "       Mocked $functionName" -ForegroundColor Cyan
                foreach ($p in $params) {
                    Write-Host "         [$p]  $(Get-Variable -Name $p -ValueOnly)" -ForegroundColor Cyan
                }
            }
        }
        Context "Sanity checking" {
            $command = Get-Command -Name Invoke-ZenossAPI

            defParam $command 'Method'
            defParam $command 'ComputerName'
            defParam $command 'Data'
            defParam $command 'Credential'

<#             It "Has a ValidateSet for the -Method parameter that accepts methods [$($validMethods -join ', ')]" {
                $validateSet = $command.Parameters.Method.Attributes | ? {$_.TypeID -eq [System.Management.Automation.ValidateSetAttribute]}
                $validateSet.ValidValues | Should Be $validMethods
            } #>
        }
        Context "Behavior testing" {

            $testComputerName = 'testzenoss.example.com'
            $testEndpoint = "device_router"
            $testAction = "getDevices"
            $testUri = "https://$testComputerName/zport/dmd/$testEndpoint"
            $testUsername = 'testUsername'
            $testPassword = 'password123'
            $testMethod = "DeviceRouter"
            $testCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $testUsername,(ConvertTo-SecureString -AsPlainText -Force $testPassword)

            Mock Invoke-WebRequest {
                ShowMockInfo 'Invoke-WebRequest' -Params 'Uri','Method','ContentType','Headers'
                $authorization = $Headers.Item('Authorization')
                if ($ShowMockData)
                 {
                    Write-Host "       Mocked Invoke-WebRequest" -ForegroundColor Cyan
                    Write-Host "         [Uri]     $Uri" -ForegroundColor Cyan
                    Write-Host "         [Method]  $Method" -ForegroundColor Cyan
                    Write-Host "         [Content-Type]  $contenttype" -ForegroundColor Cyan

                 }
            }

            It "Correctly performs all necessary HTTP method requests [$($validMethods -join ',')] to a provided URI" {
                foreach ($method in $validMethods)
                {
                    { Invoke-ZenossAPI -Method $testMethod -ComputerName $testComputerName -Endpoint $testEndpoint -Action $testAction -Credential $testCred } | Should Not Throw
                    Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$Method -eq $method -and $Uri -eq $testUri } -Scope It
                }
            }

            It "Sends the Content-Type header of application/json" {
                { Invoke-ZenossAPI -Method $testMethod -ComputerName $testComputerName -Endpoint $testEndpoint -Action $testAction -Credential $testCred } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$ContentType -eq 'application/json'} -Scope It
            }
        }

        $validTestUri = 'testzenoss.example.com'

        # This is a real REST result from Atlassian's public-facing JIRA instance, trimmed and cleaned
        # up just a bit for fields we don't care about.

        $validRestResult = @'
{
    "ipAddressString" : '10.0.0.1',
    "serialNumber"    : null,
    "pythonClass"     : 'Products.ZenModel.Device',
    "hwManufacturer"  : null,
    "collector"       : 'TestCollector',
    "osModel"         : null,
    "productionState" : '1000',
    "systems"         : {},
    "priority"        : '3',
    "hwModel"         : null,
    "tagNumber"       : null,
    "osManufacturer"  : null,
    "location"        : null,
    "groups"          : {},
    "uid"             : '/zport/dmd/Devices/Server/10.0.0.1',
    'events'          : {
        "info" : null, 
        "clear" : null,
        "warning" : null, 
        "critical" : null, 
        "error" : null, 
        "debug" : null
    },
    'name'            : 'testhostname'
}
'@
        
        $validObjResult = ConvertFrom-Json -InputObject $validRestResult
         
            It "Outputs an object representation of JSON returned from Zenoss" {

                $testEndpoint = "device_router"
                $testAction = "getDevices"
                $testUsername = 'testUsername'
                $testPassword = 'password123'
                $testMethod = "DeviceRouter"
                $testMethod = "DeviceRouter"
                $testComputerName = 'testzenoss.example.com'
                $testUri = "https://$testComputerName/zport/dmd/$testEndpoint"
                
                Mock Invoke-WebRequest -ParameterFilter {$Method -eq 'Post' -and $Uri -eq $testUri} {
                    ShowMockInfo 'Invoke-WebRequest' -Params 'Uri','Method'
                    #Write-Output [PSCustomObject] @{
                    Write-Output $validRestResult
                    #}
                }
                

                $testCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $testUsername,(ConvertTo-SecureString -AsPlainText -Force $testPassword)
                
                $result =  Invoke-ZenossAPI -Method $testMethod -ComputerName $testComputerName -Endpoint $testEndpoint -Action $testAction -Credential $testCred
                $result | Should Not BeNullOrEmpty

                # Compare each property in the result returned to the expected result
                foreach ($property in (Get-Member -InputObject $result | ? {$_.MemberType -eq 'NoteProperty'})) {
                    $result.$property | Should Be $validObjResult.$property
                }
            }
        } 
    }
