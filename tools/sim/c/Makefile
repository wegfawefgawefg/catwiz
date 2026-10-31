# The C balance sim: make, then ./catwiz-sim (main.c says how). The content header is made
# from tools/sim/proposal by gen.py, so the tables stay in one place.
CC ?= cc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -ffp-contract=off -g
SRC = main.c battle.c foes.c items.c judge.c players.c search.c draft.c rewards.c run.c \
      report.c tell.c pool.c rng.c combos.c value.c
TABLES = $(wildcard ../proposal/*.tsp) ../content.py ../tsp.py gen.py

catwiz-sim: $(SRC) *.h gen_content.h
	$(CC) $(CFLAGS) -o $@ $(SRC) -lpthread

gen_content.h: $(TABLES)
	python3 gen.py > $@

clean:
	rm -f catwiz-sim gen_content.h
