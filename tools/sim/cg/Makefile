# The catalog sim: make, then ./catwiz-sim (main.c says how). The content header is made from
# game/content by gen.py, so every row, step and number stays in the game's files.
CC ?= cc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -ffp-contract=off -g
SRC = main.c battle.c hit.c fx.c play.c foes.c judge.c players.c search.c value.c draft.c \
      rewards.c run.c worth.c report.c tell.c pool.c rng.c study.c broken.c
CONTENT = $(wildcard ../../../game/content/*.tsp) ../../../game/state.tsp \
          ../../../game/battle/turn.tsp ../../../game/battle/offer.tsp ../catalog.py ../tsp.py gen.py

ENGINE = battle.c hit.c fx.c play.c foes.c tell.c rng.c

all: catwiz-sim catwiz-check

catwiz-sim: $(SRC) *.h gen_content.h
	$(CC) $(CFLAGS) -o $@ $(SRC) -lpthread -lm

# one step from a position read off the real game (validate.py)
catwiz-check: check.c $(ENGINE) *.h gen_content.h
	$(CC) $(CFLAGS) -o $@ check.c $(ENGINE) -lm

gen_content.h: $(CONTENT)
	python3 gen.py > $@

clean:
	rm -f catwiz-sim catwiz-check gen_content.h
