# instantiate and configure ps
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {32} CONFIG.PCW_USE_S_AXI_HP1 {1} CONFIG.PCW_S_AXI_HP1_DATA_WIDTH {32} CONFIG.PCW_USE_S_AXI_HP2 {1} CONFIG.PCW_S_AXI_HP2_DATA_WIDTH {32} CONFIG.PCW_USE_S_AXI_HP3 {1} CONFIG.PCW_S_AXI_HP3_DATA_WIDTH {32} CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {0} CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {0} CONFIG.PCW_SD0_PERIPHERAL_ENABLE {0} CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0} CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {0}] [get_bd_cells processing_system7_0]

# instantiate and configure dmas
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
set_property -dict [list CONFIG.c_include_sg {0} CONFIG.c_sg_length_width {26} CONFIG.c_sg_include_stscntrl_strm {0}] [get_bd_cells axi_dma_0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_dma_0/M_AXI_MM2S} Slave {/processing_system7_0/S_AXI_HP0} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_dma_0/S_AXI_LITE} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/axi_dma_0/M_AXI_S2MM} Slave {/processing_system7_0/S_AXI_HP0} intc_ip {/axi_mem_intercon} master_apm {0}}  [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
copy_bd_objs /  [get_bd_cells {axi_dma_0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_dma_1/M_AXI_MM2S} Slave {/processing_system7_0/S_AXI_HP1} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP1]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_dma_1/S_AXI_LITE} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_dma_1/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/axi_dma_1/M_AXI_S2MM} Slave {/processing_system7_0/S_AXI_HP1} intc_ip {/axi_mem_intercon_1} master_apm {0}}  [get_bd_intf_pins axi_dma_1/M_AXI_S2MM]
copy_bd_objs /  [get_bd_cells {axi_dma_0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_dma_2/M_AXI_MM2S} Slave {/processing_system7_0/S_AXI_HP2} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP2]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_dma_2/S_AXI_LITE} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_dma_2/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/axi_dma_2/M_AXI_S2MM} Slave {/processing_system7_0/S_AXI_HP2} intc_ip {/axi_mem_intercon_2} master_apm {0}}  [get_bd_intf_pins axi_dma_2/M_AXI_S2MM]
copy_bd_objs /  [get_bd_cells {axi_dma_0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_dma_3/M_AXI_MM2S} Slave {/processing_system7_0/S_AXI_HP3} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP3]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_dma_3/S_AXI_LITE} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_dma_3/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/axi_dma_3/M_AXI_S2MM} Slave {/processing_system7_0/S_AXI_HP3} intc_ip {/axi_mem_intercon_3} master_apm {0}}  [get_bd_intf_pins axi_dma_3/M_AXI_S2MM]

# instantiate broadcaster
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0
set_property -dict [list CONFIG.NUM_MI {5} CONFIG.M02_TDATA_REMAP {tdata[7:0]} CONFIG.M03_TDATA_REMAP {tdata[7:0]} CONFIG.M04_TDATA_REMAP {tdata[7:0]}] [get_bd_cells axis_broadcaster_0]

# instantiate knncluster 
create_bd_cell -type ip -vlnv user.org:user:knnAccelerator:1.0 knnAccelerator_0
copy_bd_objs /  [get_bd_cells {knnAccelerator_0}]
copy_bd_objs /  [get_bd_cells {knnAccelerator_0}]
copy_bd_objs /  [get_bd_cells {knnAccelerator_0}]

# connect dmas, broadcaster and knnclusters and apply automations
connect_bd_intf_net [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_0/m_axis] [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_1/m_axis] [get_bd_intf_pins axi_dma_1/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_2/m_axis] [get_bd_intf_pins axi_dma_2/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_3/m_axis] [get_bd_intf_pins axi_dma_3/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_0/sp_axis] [get_bd_intf_pins axis_broadcaster_0/M00_AXIS]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_1/sp_axis] [get_bd_intf_pins axis_broadcaster_0/M01_AXIS]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_2/sp_axis] [get_bd_intf_pins axis_broadcaster_0/M02_AXIS]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_3/sp_axis] [get_bd_intf_pins axis_broadcaster_0/M03_AXIS]
connect_bd_intf_net [get_bd_intf_pins knnAccelerator_0/sb_axis] [get_bd_intf_pins axis_broadcaster_0/M04_AXIS]
connect_bd_intf_net [get_bd_intf_pins axi_dma_1/M_AXIS_MM2S] [get_bd_intf_pins knnAccelerator_1/sb_axis]
connect_bd_intf_net [get_bd_intf_pins axi_dma_2/M_AXIS_MM2S] [get_bd_intf_pins knnAccelerator_2/sb_axis]
connect_bd_intf_net [get_bd_intf_pins axi_dma_3/M_AXIS_MM2S] [get_bd_intf_pins knnAccelerator_3/sb_axis]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins axis_broadcaster_0/aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins knnAccelerator_0/m_axis_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins knnAccelerator_1/m_axis_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins knnAccelerator_1/sb_axis_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins knnAccelerator_2/m_axis_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins knnAccelerator_2/sb_axis_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins knnAccelerator_3/m_axis_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins knnAccelerator_3/sb_axis_aclk]

# regenerate, validate and save design
regenerate_bd_layout
validate_bd_design
save_bd_design

