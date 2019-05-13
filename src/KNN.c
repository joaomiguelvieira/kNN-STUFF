#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "xil_printf.h"
#include "xil_cache.h"
#include "xtime_l.h"
#include "xil_mmu.h"

#include "DMAInterface.h"

/* ==============================================================
 * ========== CHANGE PARAMETERS TO ADAPT TO THE SYSTEM ==========
 * ============================================================== */
#define N_NEAREST 5
#define N_CLASSES 29
#define N_COORDINATES 8
#define N_TEST_SAMPLES 1393
#define N_CONTROL_SAMPLES 2784

//#define DEBUG
#define RUN_SW
#define RUN_HW
/* ============================================================== */

#if PARALLEL_CFG == 1
#define CTRL_PER_CLUSTER  N_CONTROL_SAMPLES / NUMBER_OF_DMA
#define CTRL_LAST_CLUSTER CTRL_PER_CLUSTER + (N_CONTROL_SAMPLES % NUMBER_OF_DMA)
#endif

/* reservation of memory addresses */
#define CONTROL_SAMPLES_START_ADDR 0x00100000
#define TEST_SAMPLES_START_ADDR (CONTROL_SAMPLES_START_ADDR + 4 * N_COORDINATES * N_CONTROL_SAMPLES)
#define CLASSES_START_ADDR (TEST_SAMPLES_START_ADDR + 4 * N_COORDINATES * N_TEST_SAMPLES)
#define DISTANCES_START_ADDR (CLASSES_START_ADDR + 4 * N_CONTROL_SAMPLES)
#define RESULTS_HW_START_ADDR (DISTANCES_START_ADDR + 4 * N_CONTROL_SAMPLES)
#define RESULTS_SW_START_ADDR (RESULTS_HW_START_ADDR + 4 * N_TEST_SAMPLES * N_NEAREST)
#define CLASSIFICATION_RESULTS_HW (RESULTS_SW_START_ADDR + 4 * N_TEST_SAMPLES * N_NEAREST)
#define CLASSIFICATION_RESULTS_SW (CLASSIFICATION_RESULTS_HW + 4 * N_TEST_SAMPLES)

/* memory to be used as auxiliary if there is the need of big vectors in functions */
#define AUXILIARY_MEMORY (CLASSIFICATION_RESULTS_SW + 4 * N_TEST_SAMPLES)

/* pointers to memory addresses */
volatile float *control_samples, *test_samples, *distances;
volatile int *class, *resultsHW, *resultsSW, *classResultsHW, *classResultsSW;

/* alias to ease memory addressing */
#define CS(S,C) (float) (control_samples[S * N_COORDINATES + (C)])
#define TS(S,C) (float) (test_samples[S * N_COORDINATES + (C)])
#define D(S)    (float) (distances[S])
#define RH(S,N)	(int) (resultsHW[S * N_NEAREST + N])
#define RS(S,N)	(int) (resultsSW[S * N_NEAREST + N])
#define C(S)	(int) (class[S])
#define CRH(S)  (int) (classResultsHW[S])
#define CRS(S)  (int) (classResultsSW[S])

/* auxiliary structures */
typedef enum {hw, sw} System;

/**
 * @brief for a given system (hardware or software) this routine performs the classification of all
 * 		  the test samples regarding the classes to witch the N_NEAREST nearest neighbors belong to
 * @param System system: hw or sw
 * */
void classify(System system) {
	for(int i = 0; i < N_TEST_SAMPLES; i++) {
		/* vector that will store the number of votes for each class */
		int classes[N_CLASSES];

		for(int j = 0; j < N_CLASSES; j++)
			classes[j] = 0;

		/* each nearest neighbor does its vote */
		for(int j = 0; j < N_NEAREST; j++)
			classes[C(system == hw ? RH(i, j) : RS(i, j))]++;

		/* get the winning class */
		int class = 0;
		for(int j = 0; j < N_CLASSES; j++)
			if(classes[class] < classes[j])
				class = j;

		/* assign class to test sample */
		if(system == hw)
			*(classResultsHW + i) = class;
		else
			*(classResultsSW + i) = class;
	}
}

/**
 * @brief performs the euclidean distance between one test sample and one control sample in software
 * @param int testSample: identifier of the test sample
 * @param int controlSample: identifier of the control sample
 * @return float: euclidean distance between the two points
 * */
float euclideanDistanceSW(int testSample, int controlSample) {
	float aux, distance = 0;

	/* calculate the euclidean distance except the square root (not necessary) */
	for(int k = 0; k < N_COORDINATES; k++) {
		aux = TS(testSample, k) - CS(controlSample, k);
		distance += aux * aux;
	}

	return distance;
}

/**
 * @brief prints the results calculated by both software and hardware versions
 * */
void printResults() {
	xil_printf("\n================= RESULTS =================\n\r");
	xil_printf("    |       [HW]        |       [SW]       \n\r");
	xil_printf("-------------------------------------------\n\r");

	for(int i = 0; i < N_TEST_SAMPLES; i++) {
		xil_printf("%d | ", i + N_CONTROL_SAMPLES + 1);

#if PARALLEL_CFG == 0
		for(int j = N_NEAREST - 1; j >= 0; j--)
			xil_printf("%2d ", RH(i, j));
#else
		for(int j = 0; j < N_NEAREST; j++)
			xil_printf("%2d ", RH(i, j));
#endif

		xil_printf("-> %2d", CRH(i));

		xil_printf(" | ");

		for(int j = 0; j < N_NEAREST; j++)
			xil_printf("%2d ", RS(i, j));

		xil_printf("-> %2d\n\r", CRS(i));
	}
}

/** @brief given the vector of distances between a test sample and all the control samples, this
 * functions retrieves the N_NEAREST nearest control samples to the given test sample */
void retrieveShortest(int testSample) {
	int *aux = (int *) AUXILIARY_MEMORY;

	/* initialize indexes */
	for(int i = 0; i < N_CONTROL_SAMPLES; i++)
		aux[i] = i;

	/* sort the vector until position N_NEAREST */
	for(int i = 0; i < N_NEAREST; i++) {
		int idx = i;

		for(int j = i + 1; j < N_CONTROL_SAMPLES; j++)
			if(D(j) < D(idx))
				idx = j;

		float min = D(idx);
		*(distances + idx) = D(i);
		*(distances + i) = min;

		int minIdx = aux[idx];
		aux[idx] = aux[i];
		aux[i] = minIdx;

		/* assign one result of N_NEAREST */
		*(resultsSW + N_NEAREST * testSample + i) = minIdx;
	}
}

#if PARALLEL_CFG == 0
/**
 * @brief performs the euclidean distance between four test samples and all the control samples in
 * 	      hardware using four similar dedicated units
 * @param int testSample: identifier of the first test sample (the others follow this one)
 * */
void euclideanDistanceHW(int testSample) {
	/* send all the test samples (one per accelerator) */
	for(int i = 0; i < CORES_PER_DMA; i++) {
		/* interleave transference by using sequences of cores that are attached to different DMAs */
		for(int j = 0; j < NUMBER_OF_DMA; j++)
			DMATransfer((void *) (test_samples + ((testSample + j * CORES_PER_DMA + i) * N_COORDINATES)), 4 * N_COORDINATES, send, j);

		/* wait for all the DMAs to complete */
		for(int j = 0; j < NUMBER_OF_DMA; j++)
			DMAWaitForCompletion(send, j);
	}

	/* stream all the control samples coordinates concatenated */
	DMATransfer((void *) control_samples, 4 * N_COORDINATES * N_CONTROL_SAMPLES, send, 0);

	/* wait for the end of the stream */
	DMAWaitForCompletion(send, 0);

	/* retrieve the nearest neighbors for each of the test samples sent to the units */
	for(int i = 0; i < CORES_PER_DMA; i++) {
		/* interleave transference by using sequences of cores that are attached to different DMAs */
		for(int j = 0; j < NUMBER_OF_DMA; j++)
			DMATransfer((void *) (resultsHW + (testSample + j * CORES_PER_DMA + i) * N_NEAREST), 4 * N_NEAREST, recv, j);

		/* wait for all the DMAs to complete */
		for(int j = 0; j < NUMBER_OF_DMA; j++)
			DMAWaitForCompletion(recv, j);
	}

	return;
}
#else
/**
 * @brief merges the results obtained by the different accelerators, since each accelerator calculates
 *        the k nearest neighbors considering only a part of the training set
 * @param int testSample: identifier of the first test sample (the others follow this one)
 * */
void mergeResults(int testSample) {
	int *aux = (int *) AUXILIARY_MEMORY;
	float *dist = (float *) (AUXILIARY_MEMORY + 4 * (NUMBER_ACCELERATORS * N_NEAREST));

	/* for all the processed testing samples */
	for(int i = 0; i < CORES_PER_DMA; i++) {
		/* fix indexes */
		for(int j = 0; j < NUMBER_OF_DMA * N_NEAREST; j++)
			aux[j] += j / N_NEAREST * CTRL_PER_CLUSTER;

		/* calculate distances */
		for(int j = 0; j < NUMBER_OF_DMA * N_NEAREST; j++)
			dist[j] = euclideanDistanceSW(testSample + i, aux[j]);

		/* find knn */
		for(int j = 0; j < N_NEAREST; j++) {
			int idx = j;

			for(int k = j + 1; k < NUMBER_OF_DMA * N_NEAREST; k++)
				if(dist[k] < dist[idx])
					idx = k;

			float min = dist[idx];
			dist[idx] = dist[j];
			dist[j] = min;

			int minIdx = aux[idx];
			aux[idx] = aux[j];
			aux[j] = minIdx;

			/* assign one result of N_NEAREST */
			*(resultsHW + N_NEAREST * (testSample + i) + j) = minIdx;
		}

		/* increment pointers */
		aux += NUMBER_OF_DMA * N_NEAREST;
		dist += NUMBER_OF_DMA * N_NEAREST;
	}

	return;
}

/**
 * @brief performs the euclidean distance between four test samples and all the control samples in
 * 	      hardware using four similar dedicated units
 * @param int testSample: identifier of the first test sample (the others follow this one)
 * */
void euclideanDistanceHW(int testSample) {
	/* broadcast testing samples */
	for(int i = 0; i < CORES_PER_DMA; i++) {
		DMATransfer((void *) (test_samples + ((testSample + i) * N_COORDINATES)), 4 * N_COORDINATES, send, 0);
		DMAWaitForCompletion(send, 0);
	}

	/* send partitions of training set */
	for(int i = 0; i < NUMBER_OF_DMA; i++)
		DMATransfer((void *) (control_samples + (i * CTRL_PER_CLUSTER) * N_COORDINATES), 4 * N_COORDINATES * (i != NUMBER_OF_DMA - 1 ? CTRL_PER_CLUSTER : CTRL_LAST_CLUSTER), send, i);

	/* wait for training set partitions to be sent */
	for(int i = 0; i < NUMBER_OF_DMA; i++)
		DMAWaitForCompletion(send, i);

	/* retrieve the nearest neighbors for each of the test samples sent to the units */
	for(int i = 0; i < CORES_PER_DMA; i++) {
		/* interleave transference by using sequences of cores that are attached to different DMAs */
		for(int j = 0; j < NUMBER_OF_DMA; j++)
			DMATransfer((void *) (AUXILIARY_MEMORY + 4 * (j + i * NUMBER_OF_DMA) * N_NEAREST), 4 * N_NEAREST, recv, j);

		/* wait for all the DMAs to complete */
		for(int j = 0; j < NUMBER_OF_DMA; j++)
			DMAWaitForCompletion(recv, j);
	}

	/* merge the results of the several accelerators */
	mergeResults(testSample);

	return;
}
#endif

int main() {

#if !defined(DEBUG) && defined(RUN_HW)
	XTime tStartHW, tEndHW;
#endif

#if !defined(DEBUG) && defined(RUN_SW)
	XTime tStartSW, tEndSW;
#endif

	/* initialize pointers to memory regions */
	control_samples = (float *) CONTROL_SAMPLES_START_ADDR;
	test_samples = (float *) TEST_SAMPLES_START_ADDR;
	distances = (float *) DISTANCES_START_ADDR;
	class = (int *) CLASSES_START_ADDR;
	resultsHW = (int *) RESULTS_HW_START_ADDR;
	resultsSW = (int *) RESULTS_SW_START_ADDR;
	classResultsHW = (int *) CLASSIFICATION_RESULTS_HW;
	classResultsSW = (int *) CLASSIFICATION_RESULTS_SW;

#if defined(RUN_HW) || defined(DEBUG)
	/* initialize DMA interfaces */
	for(int i = 0; i < NUMBER_OF_DMA; i++) {
		if(initXAxiDmaSimplePollMode(i) == FAILURE) {
			xil_printf("[ERROR] Could not initialize DMA %d\n\r", i);
			return -1;
		}
	}
#endif

#if !defined(DEBUG) && defined(RUN_HW)
	XTime_GetTime(&tStartHW);
#endif

#if defined(RUN_HW) || defined(DEBUG)
#if PARALLEL_CFG == 0
	/* perform the algorithm in hardware */
	for(int i = 0; i < N_TEST_SAMPLES; i += NUMBER_ACCELERATORS) {
		Xil_DCacheFlushRange((INTPTR) (resultsHW + 4 * i), NUMBER_ACCELERATORS * N_NEAREST * 4);

		euclideanDistanceHW(i);
	}
#else
	/* perform the algorithm in hardware */
	for(int i = 0; i < N_TEST_SAMPLES; i += CORES_PER_DMA) {
		Xil_DCacheFlushRange((INTPTR) AUXILIARY_MEMORY, NUMBER_ACCELERATORS * N_NEAREST * 4);

		euclideanDistanceHW(i);
	}
#endif

	/* perform classification (this part is sequential and would add at most 2 units in the final
	 * speedup so it doesn't worth it to parallelize) */
	classify(hw);
#endif

#if !defined(DEBUG) && defined(RUN_HW)
	XTime_GetTime(&tEndHW);
#endif

#if !defined(DEBUG) && defined(RUN_SW)
	XTime_GetTime(&tStartSW);
#endif

#if defined(RUN_SW) || defined(DEBUG)
	/* perform the algorithm in software */
	for(int i = 0; i < N_TEST_SAMPLES; i++) {
		for(int j = 0; j < N_CONTROL_SAMPLES; j++)
			*(distances + j) = euclideanDistanceSW(i, j);

		/* sort and get the nearest neighbors in software */
		retrieveShortest(i);
	}

	/* classify the results */
	classify(sw);
#endif

#if !defined(DEBUG) && defined(RUN_SW)
	XTime_GetTime(&tEndSW);
#endif

#ifndef DEBUG
	xil_printf("\n============== SUMMARY ==============\n\r");
	xil_printf("        N Nearest | %d\n\r", N_NEAREST);
	xil_printf("        N Classes | %d\n\r", N_CLASSES);
	xil_printf("    N Coordinates | %d\n\r", N_COORDINATES);
	xil_printf("   N Test Samples | %d\n\r", N_TEST_SAMPLES);
	xil_printf("N Control Samples | %d\n\r", N_CONTROL_SAMPLES);

#ifdef RUN_HW
	xil_printf("-------------------------------------\n\r");
	xil_printf("   N Accelerators | %d\n\r", NUMBER_ACCELERATORS);
	xil_printf("            N DMA | %d\n\r", NUMBER_OF_DMA);
	xil_printf("    Cores per DMA | %d\n\r", CORES_PER_DMA);
	xil_printf(" Parallel config. | %d\n\r", PARALLEL_CFG);
#endif

#ifdef RUN_SW
	xil_printf("-------------------------------------\n\r");
	    printf("    Software Time | %.2f us\n\r", 1.0 * (tEndSW - tStartSW) / (COUNTS_PER_SECOND/1000000));
	    printf("  Software Cycles | %llu\n\r", 2 * (tEndSW - tStartSW));
#endif

#ifdef RUN_HW
	xil_printf("-------------------------------------\n\r");
	    printf("    Hardware Time | %.2f us\n\r", 1.0 * (tEndHW - tStartHW) / (COUNTS_PER_SECOND/1000000));
	    printf("  Hardware Cycles | %llu\n\r", 2 * (tEndHW - tStartHW));
#endif

#if defined(RUN_HW) && defined(RUN_SW)
	float speedup = 1.0 * ((tEndSW - tStartSW) / (COUNTS_PER_SECOND/1000000)) / ((tEndHW - tStartHW) / (COUNTS_PER_SECOND/1000000));
	xil_printf("-------------------------------------\n\r");
	    printf("          Speedup | %.2f\n\r", speedup);
	    printf("   Per sample (~) | %.2f\n\r", (PARALLEL_CFG == 0) ? speedup / NUMBER_ACCELERATORS : speedup / CORES_PER_DMA);
#endif

	xil_printf("=====================================\n\r");
#else
	printResults();
#endif

	return 0;
}
