# KNNStuff
K-Nearest Neighbors STreaming Unit for FPGA (KNNStuff) is a scalable RTL implementation of the KNN classifier. Since the design is highly reconfigurable, KNNStuff can be implemented in FPGAs of all sizes.

1. [Content of this repository](#content-of-this-repository)
2. [Pre-requisites](#pre-requisites)
3. [Create a new project](#create-a-new-project)
4. [Package the IPs](#package-the-ips)
5. [Build the block diagram](#build-the-block-diagram)
6. [Create an application project](#create-an-application-project)
7. [Run KNNStuff](#run-knn-stuff)

## Content of this repository
* `/rtl`: contains the VHDL files and the Xilinx IP files to generate the custom IP cores;
* `/scripts`: contains auxiliary scripts to help building the project;
* `/src`: contains the source code of the KNN classifier.

## Pre-requisites
To use KNNStuff, the minimum requisits are demanded:
* A host computer running Linux;
* Xilinx Vivado 2018.3 **(and only 2018.3)**:
  * Follow [this](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2018-3.html) link to download);
  * Do not forget to install the cable drivers (execute the script located at `<vivado_install_dir>/data/xicom/cable_drivers/lin64/install_script/install_drivers/install_drivers`);
* A Xilinx SoC **(this tutorial uses the Diligent Zybo board, but all procedures are also valid for the ZedBoard)**;
* A micro USB cable to connect the board to the host computer.

## Create a new project
First, you need to create a new project that will contain the synthetizable block design to program the SoC. To do that, open Vivado 2018.3 and create a new project by selecting //Create Project// from the //Quick Start// menu.

![new_project1](img/new_project1.png "New Project 1")

Select a project name and location.

![new_project2](img/new_project2.png "New Project 2")

Select //RTL project//.

![new_project3](img/new_project3.png "New Project 3")

## Package the IPs
## Build the block diagram
## Create an application project
## Run KNNStuff
