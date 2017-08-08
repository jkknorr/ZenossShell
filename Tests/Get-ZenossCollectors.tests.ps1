#
# Adapted from Get-JiraIssue.Tests.ps1, part of AtlassianPS/PSJira
# AtlasianPS/PSJira is maintained by Joshua T.
#

. $PSScriptRoot\Shared.ps1

InModuleScope ZenossShell {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Get-ZenossCollectors" {

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-ZenossAPI {}

        Context "Sanity checking" {
            $command = Get-Command -Name Get-ZenossCollectors

            function defParam($name)
            {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'ComputerName'
            defParam 'Credential'
        }

        Context "Behavior testing" {
            Mock Invoke-ZenossAPI {
                if ($ShowMockData)
                {
                    Write-Host "       Mocked Invoke-ZenossAPI" -ForegroundColor Cyan
                    Write-Host "         [ComputerName]     $ComputerName" -ForegroundColor Cyan
                    Write-Host "         [Endpoint]  $Endpoint" -ForegroundColor Cyan
                    Write-Host "         [Action]  $Action" -ForegroundColor Cyan
                    Write-Host "         [Method]  $Method" -ForegroundColor Cyan
                }
            }

            It "Returns all collectors" {

                # In order to test this, we'll need a slightly more elaborate
                # mock that actually returns some data.

                Mock Invoke-ZenossAPI {
                    if ($ShowMockData)
                    {
                        Write-Host "       Mocked Invoke-ZenossAPI" -ForegroundColor Cyan
                        Write-Host "         [ComputerName]     $ComputerName" -ForegroundColor Cyan
                        Write-Host "         [Endpoint]  $Endpoint" -ForegroundColor Cyan
                        Write-Host "         [Action]  $Action" -ForegroundColor Cyan
                        Write-Host "         [Method]  $Method" -ForegroundColor Cyan
                    }

                    ConvertFrom-Json2 @'
{
    "uuid": '012345678-0123-0123-0123-0123456789ab',
    "action": 'DeviceRouter',
    "tid" : 1,
    "type" : 'rpc',
    "method" : 'getCollectors',
    "result": [ "localhost", "oneCollector", "twoCollector" ]
}
'@
                }

                $testComputerName = 'testzenoss.example.com'
                $testEndpoint = "device_router"
                $testAction = "getCollectors"
                $testUri = "https://$testComputerName/zport/dmd/$testEndpoint"
                $testUsername = 'testUsername'
                $testPassword = 'password123'
                $testMethod = "DeviceRouter"
                $testCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $testUsername,(ConvertTo-SecureString -AsPlainText -Force $testPassword)

                New-Alias -Name ConvertFrom-Json2 -Value ConvertFrom-Json

                { Get-ZenossCollectors -ComputerName $testComputerName -Credential $testCred } | Should Not Throw

                # This should call Invoke-ZenossAPI once
                Assert-MockCalled -CommandName Invoke-ZenossAPI -ModuleName ZenossShell -Times 1 -Scope It -ParameterFilter { $Method -eq 'getCollectors' -and $ComputerName -like $testComputerName }
            }
        }
    }
}
