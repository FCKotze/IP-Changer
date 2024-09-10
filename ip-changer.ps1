# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Powerplants IP Changer'
$form.Size = New-Object System.Drawing.Size(500,650)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Create a function to create styled buttons
function New-StyledButton {
    param($Text, $Location)
    $button = New-Object System.Windows.Forms.Button
    $button.Location = $Location
    $button.Size = New-Object System.Drawing.Size(460,40)
    $button.Text = $Text
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 1
    $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(200,200,200)
    $button.BackColor = [System.Drawing.Color]::FromArgb(240,240,240)
    $button.ForeColor = [System.Drawing.Color]::FromArgb(60,60,60)
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(230,230,230) })
    $button.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(240,240,240) })
    return $button
}

# Create and add controls to the form
$adapterLabel = New-Object System.Windows.Forms.Label
$adapterLabel.Location = New-Object System.Drawing.Point(20,20)
$adapterLabel.Size = New-Object System.Drawing.Size(280,20)
$adapterLabel.Text = 'Select Network Adapter:'
$form.Controls.Add($adapterLabel)

$adapterList = New-Object System.Windows.Forms.ComboBox
$adapterList.Location = New-Object System.Drawing.Point(20,45)
$adapterList.Size = New-Object System.Drawing.Size(460,30)
$adapterList.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($adapterList)

$currentIPLabel = New-Object System.Windows.Forms.Label
$currentIPLabel.Location = New-Object System.Drawing.Point(20,80)
$currentIPLabel.Size = New-Object System.Drawing.Size(320,20)
$currentIPLabel.Text = 'Current IP: '
$form.Controls.Add($currentIPLabel)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(380,75)
$refreshButton.Size = New-Object System.Drawing.Size(100,30)
$refreshButton.Text = 'Refresh'
$refreshButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$refreshButton.FlatAppearance.BorderSize = 1
$refreshButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($refreshButton)

$button1 = New-StyledButton -Text 'Set Static IP to 192.168.1.220 (Default CPC and Transrouter)' -Location (New-Object System.Drawing.Point(20,120))
$form.Controls.Add($button1)

$button2 = New-StyledButton -Text 'Set Static IP to 172.17.16.220 (Default Connext Install)' -Location (New-Object System.Drawing.Point(20,170))
$form.Controls.Add($button2)

$button3 = New-StyledButton -Text 'Set Static IP to 172.17.1.220 (Default Gateway)' -Location (New-Object System.Drawing.Point(20,220))
$form.Controls.Add($button3)

$button4 = New-StyledButton -Text 'Set DHCP' -Location (New-Object System.Drawing.Point(20,270))
$form.Controls.Add($button4)

$button5 = New-StyledButton -Text 'Manual Setup' -Location (New-Object System.Drawing.Point(20,320))
$form.Controls.Add($button5)

$pingButton = New-StyledButton -Text 'Ping Function' -Location (New-Object System.Drawing.Point(20,370))
$form.Controls.Add($pingButton)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20,420)
$outputBox.Size = New-Object System.Drawing.Size(460,180)
$outputBox.Multiline = $true
$outputBox.ScrollBars = 'Vertical'
$outputBox.ReadOnly = $true
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputBox.BackColor = [System.Drawing.Color]::FromArgb(250,250,250)
$form.Controls.Add($outputBox)

# Functions
function Get-NetworkAdapters {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    return $adapters
}

function Set-StaticIP {
    param(
        [string]$AdapterName,
        [string]$IPAddress,
        [string]$SubnetMask,
        [string]$Gateway
    )
    try {
        $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction Stop
        $interface = $adapter | Get-NetIPInterface -AddressFamily IPv4
        
        # Remove existing IP configurations
        $interface | Remove-NetIPAddress -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        $interface | Remove-NetRoute -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue

        # Set new IP configuration
        New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $Gateway -ErrorAction Stop
        Set-NetIPInterface -InterfaceAlias $AdapterName -Dhcp Disabled -ErrorAction Stop
        
        $outputBox.AppendText("Static IP address set to: $IPAddress`r`n")
        Start-Sleep -Seconds 2
        Update-CurrentIPDisplay
    } catch {
        $outputBox.AppendText("Error setting static IP: $_`r`n")
    }
}

function Enable-DHCP {
    param([string]$AdapterName)
    try {
        $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction Stop

        # Remove existing IP configurations
        Remove-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $AdapterName -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue

        # Enable DHCP
        Set-NetIPInterface -InterfaceAlias $AdapterName -Dhcp Enabled -ErrorAction Stop
        Set-DnsClientServerAddress -InterfaceAlias $AdapterName -ResetServerAddresses -ErrorAction Stop

        # Restart the adapter to ensure changes take effect
        Restart-NetAdapter -Name $AdapterName -ErrorAction Stop

        $outputBox.AppendText("DHCP enabled for $AdapterName`r`nAdapter has been restarted.`r`n")
        
        # Wait for DHCP to assign an IP (adjust time if needed)
        Start-Sleep -Seconds 10
        Update-CurrentIPDisplay
    } catch {
        $outputBox.AppendText("Error enabling DHCP: $_`r`n")
    }
}

function PopulateAdapterList {
    $adapterList.Items.Clear()
    Get-NetworkAdapters | ForEach-Object {
        $adapterList.Items.Add($_.Name)
    }
    if ($adapterList.Items.Count -gt 0) {
        $adapterList.SelectedIndex = 0
        Update-CurrentIPDisplay
    }
}

function Show-InputBox {
    param(
        [string]$prompt,
        [string]$title,
        [string]$default
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(300,150)
    $form.StartPosition = 'CenterScreen'

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = $prompt
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,40)
    $textBox.Size = New-Object System.Drawing.Size(260,20)
    $textBox.Text = $default
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,70)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150,70)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        return $textBox.Text
    }
    return $null
}

function Start-ContinuousPing {
    param([string]$IPAddress)
    
    $pingForm = New-Object System.Windows.Forms.Form
    $pingForm.Text = "Continuous Ping: $IPAddress"
    $pingForm.Size = New-Object System.Drawing.Size(400,300)
    $pingForm.StartPosition = 'CenterScreen'

    $pingOutputBox = New-Object System.Windows.Forms.TextBox
    $pingOutputBox.Location = New-Object System.Drawing.Point(10,10)
    $pingOutputBox.Size = New-Object System.Drawing.Size(360,200)
    $pingOutputBox.Multiline = $true
    $pingOutputBox.ScrollBars = 'Vertical'
    $pingOutputBox.ReadOnly = $true
    $pingForm.Controls.Add($pingOutputBox)

    $stopButton = New-Object System.Windows.Forms.Button
    $stopButton.Location = New-Object System.Drawing.Point(150,220)
    $stopButton.Size = New-Object System.Drawing.Size(75,23)
    $stopButton.Text = 'Stop'
    $pingForm.Controls.Add($stopButton)

    $pingTimer = New-Object System.Windows.Forms.Timer
    $pingTimer.Interval = 1000 # 1 second

    $pingTimer.Add_Tick({
        $ping = New-Object System.Net.NetworkInformation.Ping
        $result = $ping.Send($IPAddress)
        if ($result.Status -eq 'Success') {
            $pingOutputBox.AppendText("Reply from $IPAddress`: bytes=$($result.Buffer.Length) time=$($result.RoundtripTime)ms TTL=$($result.Options.Ttl)`r`n")
        } else {
            $pingOutputBox.AppendText("Ping to $IPAddress failed: $($result.Status)`r`n")
        }
    })

    $stopButton.Add_Click({
        $pingTimer.Stop()
        $pingForm.Close()
    })

    $pingForm.Add_Shown({
        $pingTimer.Start()
    })

    $pingForm.ShowDialog()
}

function Update-CurrentIPDisplay {
    $selectedAdapter = $adapterList.SelectedItem
    if ($selectedAdapter) {
        $ip = Get-NetIPAddress -InterfaceAlias $selectedAdapter -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress
        $dhcpStatus = Get-NetIPInterface -InterfaceAlias $selectedAdapter -AddressFamily IPv4 | Select-Object -ExpandProperty Dhcp
        if ($ip) {
            $currentIPLabel.Text = "Current IP: $ip (DHCP: $dhcpStatus)"
        } else {
            $currentIPLabel.Text = "Current IP: Not assigned (DHCP: $dhcpStatus)"
        }
    } else {
        $currentIPLabel.Text = "Current IP: No adapter selected"
    }
}

# Event handlers
$refreshButton.Add_Click({ 
    PopulateAdapterList
    Update-CurrentIPDisplay
})

$adapterList.Add_SelectedIndexChanged({
    Update-CurrentIPDisplay
})

$button1.Add_Click({
    $selectedAdapter = $adapterList.SelectedItem
    if ($selectedAdapter) {
        Set-StaticIP -AdapterName $selectedAdapter -IPAddress "192.168.1.220" -SubnetMask "255.255.255.0" -Gateway "192.168.1.240"
    } else {
        $outputBox.AppendText("Please select a network adapter`r`n")
    }
})

$button2.Add_Click({
    $selectedAdapter = $adapterList.SelectedItem
    if ($selectedAdapter) {
        Set-StaticIP -AdapterName $selectedAdapter -IPAddress "172.17.16.220" -SubnetMask "255.255.255.0" -Gateway "172.17.16.240"
    } else {
        $outputBox.AppendText("Please select a network adapter`r`n")
    }
})

$button3.Add_Click({
    $selectedAdapter = $adapterList.SelectedItem
    if ($selectedAdapter) {
        Set-StaticIP -AdapterName $selectedAdapter -IPAddress "172.17.1.220" -SubnetMask "255.255.255.0" -Gateway "172.17.1.240"
    } else {
        $outputBox.AppendText("Please select a network adapter`r`n")
    }
})

$button4.Add_Click({
    $selectedAdapter = $adapterList.SelectedItem
    if ($selectedAdapter) {
        Enable-DHCP -AdapterName $selectedAdapter
    } else {
        $outputBox.AppendText("Please select a network adapter`r`n")
    }
})

$button5.Add_Click({
    $selectedAdapter = $adapterList.SelectedItem
    if ($selectedAdapter) {
        $ipAddress = Show-InputBox -prompt "Enter IP Address:" -title "Manual Setup" -default ""
        if ($ipAddress) {
            $subnetMask = Show-InputBox -prompt "Enter Subnet Mask:" -title "Manual Setup" -default "255.255.255.0"
            if ($subnetMask) {
                $gateway = Show-InputBox -prompt "Enter Default Gateway:" -title "Manual Setup" -default ""
                if ($gateway) {
                    Set-StaticIP -AdapterName $selectedAdapter -IPAddress $ipAddress -SubnetMask $subnetMask -Gateway $gateway
                } else {
                    $outputBox.AppendText("Manual setup cancelled`r`n")
                }
            } else {
                $outputBox.AppendText("Manual setup cancelled`r`n")
            }
        } else {
            $outputBox.AppendText("Manual setup cancelled`r`n")
        }
    } else {
        $outputBox.AppendText("Please select a network adapter`r`n")
    }
})

$pingButton.Add_Click({
    $ipAddress = Show-InputBox -prompt "Enter IP Address to ping:" -title "Ping Function" -default ""
    if ($ipAddress) {
        Start-ContinuousPing -IPAddress $ipAddress
    } else {
        $outputBox.AppendText("Ping function cancelled`r`n")
    }
})

# Populate adapter list when form loads
$form.Add_Shown({PopulateAdapterList})

# Show the form
$form.ShowDialog()