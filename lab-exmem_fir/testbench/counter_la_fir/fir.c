#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir
	for (int i = 0; i < N; ++i) {
		inputbuffer[i] = 0;
		outputsignal[i] = 0;
	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();
	//write down your fir
	for (int t = 0; t < N; ++t) {
		outputsignal[t] = 0;
		for (int i = 0; i <= t; ++i) {
			outputsignal[t] = outputsignal[t] + (taps[i] * inputsignal[t-i]);
		}
	}
	return outputsignal;
}
		
