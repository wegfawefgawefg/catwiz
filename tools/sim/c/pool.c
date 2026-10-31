/* A plain worker pool: each worker takes the next index until none is left. */
#include <pthread.h>
#include <stdatomic.h>

#include "pool.h"

typedef struct {
    atomic_int next;
    int n;
    void (*fn)(int, void *);
    void *ctx;
} Work;

static void *worker(void *arg) {
    Work *w = arg;
    for (;;) {
        int i = atomic_fetch_add(&w->next, 1);
        if (i >= w->n)
            return 0;
        w->fn(i, w->ctx);
    }
}

void parallel_for(int n, int jobs, void (*fn)(int i, void *ctx), void *ctx) {
    Work w;
    atomic_init(&w.next, 0);
    w.n = n;
    w.fn = fn;
    w.ctx = ctx;
    if (jobs > MOST_JOBS)
        jobs = MOST_JOBS;
    if (jobs <= 1 || n <= 1) {
        worker(&w);
        return;
    }
    pthread_t t[MOST_JOBS];
    for (int j = 0; j < jobs; j++)
        pthread_create(&t[j], 0, worker, &w);
    for (int j = 0; j < jobs; j++)
        pthread_join(t[j], 0);
}
