# The catalog sim: make, then ./catwiz-sim (main.c says how). The content header is made from
# game/content by gen.py, so every row, step and number stays in the game's files.
CC ?= cc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -ffp-contract=off -g
SRC = main.c battle.c hit.c fx.c play.c foes.c judge.c players.c search.c value.c draft.c \
      rewards.c run.c worth.c report.c tell.c pool.c rng.c study.c broken.c
CONTENT = $(wildcard ../../../game/content/*.tsp) ../../../game/state.tsp \
          ../../../game/battle/turn.tsp ../../../game/battle/offer.tsp ../catalog.py ../tsp.py gen.py

catwiz-sim: $(SRC) *.h gen_content.h
	$(CC) $(CFLAGS) -o $@ $(SRC) -lpthread -lm

gen_content.h: $(CONTENT)
	python3 gen.py > $@

clean:
	rm -f catwiz-sim gen_content.h
