/* placeholder until the searching player is written */
#include "search.h"
void search_init(void) {}
void search_turn(Player *p, Battle *b) { p->kind = P_STRONG; player_turn(p, b); p->kind = P_SEARCH; }
int search_choose(Player *p, const Kit *kit, int hp, int f, const Pick *opts, int n) { (void)p;(void)kit;(void)hp;(void)f;(void)opts;(void)n; return 0; }
int search_nap(Player *p, const Kit *kit, int hp, int heal, const Pick *up, int f) { (void)p;(void)kit;(void)hp;(void)heal;(void)up;(void)f; return 1; }
int search_door(Player *p, const Kit *kit, int hp, int f, int other) { (void)p;(void)kit;(void)hp;(void)other; return f; }
