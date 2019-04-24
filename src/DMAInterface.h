#define SUCCESS 0
#define FAILURE 1

/* ===================================================
 * ========== CHANGE NUMBER OF ACCELERATORS ==========
 * =================================================== */
#define NUMBER_OF_DMA 1
#define CORES_PER_DMA 4
#define NUMBER_ACCELERATORS NUMBER_OF_DMA * CORES_PER_DMA
/* =================================================== */

typedef enum{send, recv} Way;
typedef int DeviceID;

int initXAxiDmaSimplePollMode(DeviceID deviceID);
int DMATransfer(void *baseAddr, int nBytes, Way w, DeviceID deviceID);
void DMAWaitForCompletion(Way w, DeviceID deviceID);
