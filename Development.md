# Development Notes

This note describes the development workflow on a WLAN Pi for this package. It assumes the use of Visual Studio code and direct development of code on a physical WLAN Pi, with git pushes direct from the WLAN Pi to the Github repo. 

## Dev Environment

Tools required:
 - Visual Studio Code (VSC)
 - VSC plugin: Remote Explorer
 - WLAN Pi

1. SSH to the WLAN Pi from your dev machine
2. (On WLAN Pi CLI) Clone this repo : `git clone https://github.com/WLAN-Pi/wlanpi-wconsole.git`
3. (On WLAN Pi CLI) change to the repo dir: `cd wlanpi-wconsole`
3. (On WLAN Pi CLI) set git username: `git config --local user.name yourgitusername`
4. (On WLAN Pi CLI) set it email address: `git config --local user.email yourgitemail@myowndomain.com`
5. (On WLAN Pi CLI) add required build tools: `sudo apt-get install devscripts`
5. (VSC) Set up a new target in Remote Explorer for the WLAN pi: Remote Explorer > SSH Targets > Configure
6. (VSC) Open new target in Remote Explorer
7. (VSC) Select the folder on the WLAN Pi 
8. (VSC) Select/create branch as required
9. (VSC) open a bash terminal for CLI operations on the WLAN Pi
8. (VSC) Make code updates as required on cloned copy of repo on the WLAN Pi

# Building & Testing New Builds

 - Once code updates are complete, push to github using the usual push commands from the bash terminal or Source Control explorer in VSC UI
 - Build new Debian package in bash terminal using: `sudo dpkg-buildpackage -us -uc -b` 
 - The built package can be found in the parent folder from the source code
 - Move to the parent folder in the bash terminal
 - Identify the new `.deb` package file
 - Install the new package and ensure all runs as expected: `sudo dpkg -i ./wlanpi-wconsole_x.x.xx_arm64.deb`



