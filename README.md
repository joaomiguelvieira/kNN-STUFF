# KNNStuff
K-Nearest Neighbors STreaming Unit for FPGA (KNNStuff) is a scalable RTL implementation of the KNN classifier. Since the design is highly reconfigurable, KNNStuff can be implemented in FPGAs of all sizes.

1. [Content of this repository](#content-of-this-repository)
2. [Pre-requisites](#pre-requisites)
3. [Create a new project](#create-a-new-project)
4. [Package the IPs](#package-the-ips)
5. [Build the block diagram](#build-the-block-diagram)
6. [Create an application project](#create-an-application-project)
7. [Run KNNStuff](#run-knn-stuff)
8. [Customizing KNNStuff parameters](#customizing-knnstuff-parameters)

## Content of this repository
* `/rtl`: contains the VHDL files and the Xilinx IP files to generate the custom IP cores;
* `/scripts`: contains auxiliary scripts to help building the project;
* `/src`: contains the source code of the KNN classifier.

## Pre-requisites
To use KNNStuff, the minimum requisits are demanded:
* A host computer running Linux;
* Xilinx Vivado 2018.3 **(and only 2018.3)**:
  * Follow [this](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2018-3.html) link to download);
  * Download and install the board files (find instructions [here](https://reference.digilentinc.com/reference/software/vivado/board-files));
  * Do not forget to install the cable drivers (execute the script located at `<vivado_install_dir>/data/xicom/cable_drivers/lin64/install_script/install_drivers/install_drivers`).
* A Xilinx SoC **(this tutorial uses the Diligent Zybo board, but all procedures are also valid for the ZedBoard)**;
* A micro USB cable to connect the board to the host computer.

## Create a new project
First, you need to create a new project that will contain the synthetizable block design to program the SoC. To do that, open Vivado 2018.3 and create a new project by selecting *Create Project* from the *Quick Start* menu.

![new_project1](img/new_project1.png "New Project 1")

Select a project name and location.

![new_project2](img/new_project2.png "New Project 2")

Select *RTL project*.

![new_project3](img/new_project3.png "New Project 3")

Make sure that the *Target language* is VLDH.

![new_project4](img/new_project4.png "New Project 4")

Press *Next* twice without adding any constraints.

From the menu *Boards*, select *Zybo*.

![new_project5](img/new_project5.png "New Project 5")

Finally, press *Next* and *Finish* to open the newly created project.

## Package the IPs
After creating a new project, the custom IPs need to be packaged and build from the VHDL sources. To do that, select *Tools* and then *Create and Package New IP...*. Press *Next* and select *Create a new AXI4 peripheral*. Name the first IP "knnAccelerator" and press *Next*. Then, it will be necessary to create three AXI4 Stream interfaces (two slaves and one master). In the end, the list of interfaces should look the following:

![new_project6](img/new_project6.png "New Project 6")

**Note that you should create the interfaces with exactly these names and parameters. The master inteerface should have *Master* as *Interface Mode* instead of *Slave*.**

Select *Next*, *Edit IP*, and *Finish*.

To add the sources of the first IP, right-click on *Design Sources* and select *Add Sources*, *Add or create design sources*, and *Add Files*. Navigate to `rtl/knnaccelerator`, select all the files and press *Finish*. Select the files named *knnAccelerator_v1_0_m_axis*, *knnAccelerator_v1_0_sb_axis*, and *knnAccelerator_v1_0_sp_axis*, right-click and *Remove file from project...*.

In the *Sources* menu, find the *Libraries* tab. Select the file *knnCluster_Pkg.vhd*, under *Design Sources*, *VHDL*, *xil_defaultlib*. Right-click and select *Set Library*. Write *knnCluster* and select *Ok*.

From the flow navigator menu, select *Package IP*. Go through the several tabs that have review icon (small sheet of paper with a pencil) and merge all the changes (click in the suggestions presented in the yellow bar). Finally, select *Review and Package* and *Re-Package IP*. **Note that if you want to keep the project after packaging the IP, you need to select first *Edit packaging settings* deselect the option *Delete project after packaging***.

Next, you need to repeat the same procedure to the second IP.

Reopen the project that you created in section [Create a new project](#create-a-new-project), select *Tools* and then *Create and Package New IP...*. Press *Next* and select *Create a new AXI4 peripheral*. Name the second IP "knnCluster" and press *Next*. Then, it will be necessary to create three AXI4 Stream interfaces (two slaves and one master). In the end, the list of interfaces should look the following:

![new_project6](img/new_project6.png "New Project 6")

**Note that you should create the interfaces with exactly these names and parameters. The master inteerface should have *Master* as *Interface Mode* instead of *Slave*.**

Select *Next*, *Edit IP*, and *Finish*.

To add the sources of the first IP, right-click on *Design Sources* and select *Add Sources*, *Add or create design sources*, and *Add Files*. Navigate to `rtl/knncluster`, select all the files and press *Finish*. Select the files named *knnCluster_v1_0_m_axis*, *knnCluster_v1_0_sb_axis*, and *knnCluster_v1_0_sp_axis*, right-click and *Remove file from project...*.

In the *Sources* menu, find the *Libraries* tab. Select the file *knnCluster_Pkg.vhd*, under *Design Sources*, *VHDL*, *xil_defaultlib*. Right-click and select *Set Library*. Write *knnCluster* and select *Ok*.

From the flow navigator menu, select *Package IP*. Go through the several tabs that have review icon (small sheet of paper with a pencil) and merge all the changes (click in the suggestions presented in the yellow bar). Finally, select *Review and Package* and *Re-Package IP*. **Note that if you want to keep the project after packaging the IP, you need to select first *Edit packaging settings* deselect the option *Delete project after packaging***.

## Build the block diagram
## Create an application project
## Run KNNStuff
## Customizing KNNStuff parameters
