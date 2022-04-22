# Jerk Packages
This repo contains a collection of jerk packages for the [Jerk Installer script](https://github.com/kugiigi/jerk-installer). This collection contains the files for each package which you can manually install or compress them into tarballs and use the [Jerk Installer script](https://github.com/kugiigi/jerk-installer) to install.

### How to use
#### Manual Installation
It is possible to install these packages manually however, it also means backing up files and uninstalling is up to you. You also have to check if the package is compatible with your Ubuntu Touch system, at least by comparing the contents of the `ORIG` folder to your system files.

1. Download the `MOD` folder of the desired package.
2. Check the `target path` of the target component of your desired package. You may see them from the configuration files [here](https://github.com/kugiigi/jerk-installer/tree/main/components)  
   i.e. Lomiri = `/usr/share/unity8`
3. Copy all the contents of the `MOD` folder you downloaded to the `target path`. Make sure you copy the contents and not the folder `MOD` itself.
4. Depending on the affected component, you may need to restart them or just do a full reboot.  
   i.e. Lomiri = `restart unity8`
   
   
#### Installation via Jerk
Installing via the [Jerk Installer script](https://github.com/kugiigi/jerk-installer) is recommended since these packages are designed for this script. Using this script, also provides easy install and reinstall and automatic backing up of files. It also checks compatibility, at least at the basic level, before installing.
1. Download the desired package folder.
2. Compress the whole directory into a tar file. Make sure that `MOD`, `ORIG` and `config` are at the top level, NOT the package's folder name.
3. The tar file format SHOULD BE `tar.gz`. Some OS may default to a different format so you may need to open them in an archive manager and save it as `tar.gz`.
4. Use the [Jerk Installer script](https://github.com/kugiigi/jerk-installer) to install the package.  
   i.e. `jerk install KugiCollection.tar.gz`
   
   
### FAQs
1. What the hell are the Kugi Collection Packages?  
These packages contains all my, I'm Kugi :), customizations, fixes, experiments and fun stuffs that you MAY or MAY NEVER see get officially implemented. If you want specific customizations, you can ask me and I can try to create a separate package.

2. How do I know what each package does?  
You can manually check the `config` file of each package or using Jerk, run `jerk describe <package name>`.
