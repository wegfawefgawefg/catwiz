/* The sim's random numbers: Python's random.Random (MT19937 with its seeding), so a run of
   the C sim takes the same random numbers as the Python sim's run of the same seed. */
#ifndef RNG_H
#define RNG_H
#include <stdint.h>

typedef struct {
    uint32_t mt[624];
    int i;
} Mt;

void mt_seed(Mt *r, uint64_t seed);    /* random.Random(seed) */
uint32_t mt_u32(Mt *r);
uint32_t mt_bits(Mt *r, int k);        /* getrandbits(k), k 1-32 */
int mt_below(Mt *r, int n);            /* randrange(n) */
double mt_random(Mt *r);               /* random() */

#endif
