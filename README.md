# IP Changer for Priva Commissioning

IP Changer is a PowerShell-based GUI tool designed primarily for Priva Commissioning. It allows you to easily change your network adapter's IP settings on Windows systems, providing a user-friendly interface for common IP configuration tasks often needed during the commissioning process of Priva systems.

## Features

- Set predefined static IP addresses commonly used in Priva systems
- Enable DHCP
- Manual IP configuration
- View current IP settings
- Continuous ping function for network testing

## Quick Start

To run IP Changer directly from GitHub:

1. Open PowerShell as an administrator
2. Copy and paste the following command:

   ```powershell
   irm https://raw.githubusercontent.com/FCKotze/ip-changer/main/install.ps1 | iex
   ```

3. Press Enter to execute the command

This will download and run the IP Changer tool on your system.

## Troubleshooting

If you encounter an error related to the execution policy, you may need to allow running scripts from the internet. To do this:

1. Open PowerShell as an administrator
2. Run the following command:

   ```powershell
   Set-ExecutionPolicy RemoteSigned
   ```

3. Type 'Y' and press Enter when prompted

After changing the execution policy, try running the IP Changer command again.

## Important Note

Changing IP settings can affect your network connectivity. Please ensure you have the necessary permissions and understanding of your network configuration before making changes. This tool is designed for use by Priva commissioning engineers or technicians familiar with the IP requirements of Priva systems.

## Feedback and Contributions

If you encounter any issues or have suggestions for improvements, please open an issue on this GitHub repository. Contributions via pull requests are welcome!
