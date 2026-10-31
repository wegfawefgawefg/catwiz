/* MT19937 as CPython's _randommodule.c has it: init_by_array of the seed's 32-bit words,
   getrandbits(k) the top k bits of one draw, randrange by rejection on getrandbits of n's bit
   length, random() from two draws. */
#include "rng.h"

static void init_genrand(Mt *r, uint32_t s) {
    r->mt[0] = s;
    for (int i = 1; i < 624; i++)
        r->mt[i] = 1812433253u * (r->mt[i - 1] ^ (r->mt[i - 1] >> 30)) + (uint32_t)i;
    r->i = 624;
}

void mt_seed(Mt *r, uint64_t seed) {
    uint32_t key[2];
    int len = 0;
    key[len++] = (uint32_t)seed;
    if (seed >> 32)
        key[len++] = (uint32_t)(seed >> 32);
    init_genrand(r, 19650218u);
    int i = 1, j = 0;
    for (int k = 624 > len ? 624 : len; k; k--) {
        r->mt[i] = (r->mt[i] ^ ((r->mt[i - 1] ^ (r->mt[i - 1] >> 30)) * 1664525u)) + key[j] +
                   (uint32_t)j;
        i++;
        j++;
        if (i >= 624) {
            r->mt[0] = r->mt[623];
            i = 1;
        }
        if (j >= len)
            j = 0;
    }
    for (int k = 623; k; k--) {
        r->mt[i] = (r->mt[i] ^ ((r->mt[i - 1] ^ (r->mt[i - 1] >> 30)) * 1566083941u)) -
                   (uint32_t)i;
        i++;
        if (i >= 624) {
            r->mt[0] = r->mt[623];
            i = 1;
        }
    }
    r->mt[0] = 0x80000000u;
    r->i = 624;
}

uint32_t mt_u32(Mt *r) {
    if (r->i >= 624) {
        for (int k = 0; k < 624; k++) {
            uint32_t y = (r->mt[k] & 0x80000000u) | (r->mt[(k + 1) % 624] & 0x7fffffffu);
            r->mt[k] = r->mt[(k + 397) % 624] ^ (y >> 1) ^ ((y & 1) ? 0x9908b0dfu : 0);
        }
        r->i = 0;
    }
    uint32_t y = r->mt[r->i++];
    y ^= y >> 11;
    y ^= (y << 7) & 0x9d2c5680u;
    y ^= (y << 15) & 0xefc60000u;
    y ^= y >> 18;
    return y;
}

uint32_t mt_bits(Mt *r, int k) {
    return mt_u32(r) >> (32 - k);
}

int mt_below(Mt *r, int n) {
    int k = 0;
    while ((n >> k) != 0)
        k++;
    uint32_t v = mt_bits(r, k);
    while ((int)v >= n)
        v = mt_bits(r, k);
    return (int)v;
}

double mt_random(Mt *r) {
    uint32_t a = mt_u32(r) >> 5, b = mt_u32(r) >> 6;
    return (a * 67108864.0 + b) * (1.0 / 9007199254740992.0);
}
