/* Running many runs at once (pool.c): pthreads, at most 8 workers (the owner's desktop). */
#ifndef POOL_H
#define POOL_H

#ifndef MOST_JOBS
#define MOST_JOBS 8 /* the owner's desktop; -DMOST_JOBS=14 on the mini */
#endif

/* fn(i, ctx) for i in 0..n-1 on jobs threads; each i once, in any order. fn is the one
   function pointer of the sim: a worker needs to be told what to run. */
void parallel_for(int n, int jobs, void (*fn)(int i, void *ctx), void *ctx);

#endif
