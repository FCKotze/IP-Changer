# Download the main script
$url = "https://raw.githubusercontent.com/FCKotze/ip-changer/main/ip-changer.ps1"
$outputPath = "$env:TEMP\ip-changer.ps1"

Invoke-WebRequest -Uri $url -OutFile $outputPath

# Run the script
& powershell.exe -ExecutionPolicy Bypass -File $outputPath
