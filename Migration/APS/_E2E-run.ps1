# 0_PreAssessment
Write-Host "Running 0_PreAssessment step" -ForegroundColor Yellow
if (Test-Path $PSScriptRoot\Output\0_PreAssessment) {
Remove-Item -Path $PSScriptRoot\Output\0_PreAssessment -Recurse -Force
}
. $PSScriptRoot\0_PreAssessment\PreAssessmentDriver.ps1


# 1_CreateMPPScripts
Write-Host "Running 1_CreateMPPScripts step" -ForegroundColor Yellow
Remove-Item -Path $PSScriptRoot\1_CreateMPPScripts\*.csv -Recurse -Force
if (Test-Path $PSScriptRoot\Output\1_CreateMPPScripts) {
    Remove-Item -Path $PSScriptRoot\Output\1_CreateMPPScripts -Recurse -Force
}
Copy-Item -Path $PSScriptRoot\Output\0_PreAssessment\TablesToScript*.csv -Destination $PSScriptRoot\1_CreateMPPScripts -Recurse
Copy-Item -Path $PSScriptRoot\Output\0_PreAssessment\ViewsToScript*.csv -Destination $PSScriptRoot\1_CreateMPPScripts -Recurse
Copy-Item -Path $PSScriptRoot\Output\0_PreAssessment\SPsToScript*.csv -Destination $PSScriptRoot\1_CreateMPPScripts -Recurse
Copy-Item -Path $PSScriptRoot\Output\0_PreAssessment\FunctionsToScript*.csv -Destination $PSScriptRoot\1_CreateMPPScripts -Recurse
Copy-Item -Path $PSScriptRoot\Output\0_PreAssessment\IndexesToScript*.csv -Destination $PSScriptRoot\1_CreateMPPScripts -Recurse
Copy-Item -Path $PSScriptRoot\Output\0_PreAssessment\StatisticsToScript*.csv -Destination $PSScriptRoot\1_CreateMPPScripts -Recurse
Copy-Item -Path $PSScriptRoot\Output\0_PreAssessment\RolesToScript*.csv -Destination $PSScriptRoot\1_CreateMPPScripts -Recurse
Copy-Item -Path $PSScriptRoot\Output\0_PreAssessment\UsersToScript*.csv -Destination $PSScriptRoot\1_CreateMPPScripts -Recurse
. "$PSScriptRoot\1_CreateMPPScripts\ScriptMPPObjectsDriver.ps1"


# 3_FixSqlCode
Write-Host "Running 3_FixSqlCode step" -ForegroundColor Yellow
if (Test-Path $PSScriptRoot\Output\3_FixSqlCode) {
    Remove-Item -Path $PSScriptRoot\Output\3_FixSqlCode -Recurse -Force
}
. "$PSScriptRoot\3_FixSqlCode\FixSqlCodeDriver.ps1"


# 4_CreateAPSExportScriptSQLDWImportScript
Write-Host "Running 4_CreateAPSExportScriptSQLDWImportScript step" -ForegroundColor Yellow
if (Test-Path $PSScriptRoot\Output\4_CreateAPSExportScriptSQLDWImportScript) {
    Remove-Item -Path $PSScriptRoot\Output\4_CreateAPSExportScriptSQLDWImportScript -Recurse -Force
}
. "$PSScriptRoot\4_CreateAPSExportScriptSQLDWImportScript\Generate_Step4_ConfigFiles.ps1"
. "$PSScriptRoot\4_CreateAPSExportScriptSQLDWImportScript\ScriptCreateExportImportStatementsDriver.ps1"


# 5_CreateExternalTablesSQLDW
Write-Host "Running 5_CreateExternalTablesSQLDW step" -ForegroundColor Yellow
if (Test-Path $PSScriptRoot\Output\5_CreateExternalTablesSQLDW) {
    Remove-Item -Path $PSScriptRoot\Output\5_CreateExternalTablesSQLDW -Recurse -Force
}
. "$PSScriptRoot\5_CreateExternalTablesSQLDW\Generate_Step5_ConfigFiles.ps1"
. "$PSScriptRoot\5_CreateExternalTablesSQLDW\ScriptCreateExternalTableDriver.ps1"


# 6_DeployScriptsToSqldw
Write-Host "Running 6_DeployScriptsToSqldw step" -ForegroundColor Yellow
if (Test-Path $PSScriptRoot\Output\6_DeployScriptsToSqldw) {
    Remove-Item -Path $PSScriptRoot\Output\6_DeployScriptsToSqldw -Recurse -Force
}
. "$PSScriptRoot\6_DeployScriptsToSqldw\Generate_Step6_ConfigFiles.ps1"

