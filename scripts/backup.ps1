cd C:\Users\heman\SalesforceBackup

Write-Host "Retrieving Salesforce Metadata..."
sf project retrieve start --manifest manifest/package.xml

git add .

$changes = git status --porcelain

if ($changes) {
    Write-Host "Changes detected. Committing..."

    git commit -m "Automated Salesforce Backup $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    git push origin main

    Write-Host "Backup pushed to GitHub."
}
else {
    Write-Host "No metadata changes found."
}