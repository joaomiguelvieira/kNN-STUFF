#include "xaxidma.h"
#include "DMAInterface.h"

#define TX_BUFFER_BASE (MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE (MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH (MEM_BASE_ADDR + 0x004FFFFF)

XAxiDma axiDma[NUMBER_OF_DMA];

int initXAxiDmaSimplePollMode(DeviceID deviceID) {
	XAxiDma_Config *config;

	if(!(config = XAxiDma_LookupConfig(deviceID)) ||
			(XAxiDma_CfgInitialize(&axiDma[deviceID], config) != XST_SUCCESS) ||
			(XAxiDma_HasSg(&axiDma[deviceID])))
		return FAILURE;

	XAxiDma_IntrDisable(&axiDma[deviceID], XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(&axiDma[deviceID], XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

	return SUCCESS;
}

int DMATransfer(void *baseAddr, int nBytes, Way w, DeviceID deviceID) {
	int path = (w == send) ? XAXIDMA_DMA_TO_DEVICE : XAXIDMA_DEVICE_TO_DMA;

	if(XAxiDma_SimpleTransfer(&axiDma[deviceID], (UINTPTR) baseAddr, nBytes, path) != XST_SUCCESS)
		return FAILURE;

	return SUCCESS;
}

void DMAWaitForCompletion(Way w, DeviceID deviceID) {
	int path = (w == send) ? XAXIDMA_DMA_TO_DEVICE : XAXIDMA_DEVICE_TO_DMA;

	// wait for transaction to end
	while(XAxiDma_Busy(&axiDma[deviceID], path));
}
