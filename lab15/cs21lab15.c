#include <omp.h>
#include <stdio.h>

void main(void) {
    double pi = 0;
    #pragma omp parallel
    {
        double sum = 0;
        int i = 0, sign = 1, denom = 1;
        #pragma omp for private (sign, denom)
        for (i = 0; i < 1000000000; ++i) {
            sign = (i % 2) ? -1 : 1;
            denom = (1 + (i * 2)) * sign;
            sum += 4.0 / denom;
        }
        #pragma omp atomic
        pi += sum;
    }
    printf("%.9lf\n", pi);
}
