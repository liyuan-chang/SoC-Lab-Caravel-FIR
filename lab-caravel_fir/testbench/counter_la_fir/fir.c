#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	// initial your fir

	// reset control registers
	reg_fir_control = 0;

	// program coefficients and data length
	// volatile uint32_t* coeff_ptr = &reg_fir_coeff;
	// for (int i = 0; i < N; ++i) {
	// 	*(coeff_ptr + i) = taps[i];
	// }
	reg_fir_coeff_0  = taps[0];
	reg_fir_coeff_1  = taps[1];
	reg_fir_coeff_2  = taps[2];
	reg_fir_coeff_3  = taps[3];
	reg_fir_coeff_4  = taps[4];
	reg_fir_coeff_5  = taps[5];
	reg_fir_coeff_6  = taps[6];
	reg_fir_coeff_7  = taps[7];
	reg_fir_coeff_8  = taps[8];
	reg_fir_coeff_9  = taps[9];
	reg_fir_coeff_10 = taps[10];
	reg_fir_data_len = N;
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();
	// write down your fir

	// assert ap_start
	reg_fir_control = 0x00000001;

	// send x to fir and receive y from fir
	// x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
	for (int i = 0; i < N; ++i) {
		while (1) {
			// wait for fir to be ready to accept input
			if ((reg_fir_control & 0x00000010) == 0x00000010) {
				reg_fir_x = (i + 1);
				break;
			}
		}
		while (1) {
			// wait for the output of fir
			if ((reg_fir_control & 0x00000020) == 0x00000020) {
				outputsignal[i] = reg_fir_y;
				break;
			}
		}
	}

	return outputsignal;
}
		
