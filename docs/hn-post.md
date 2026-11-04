# Show HN post: draft

Draft, 2026-11-04. No AI disclaimer (the owner, 2026-11-04: building with AI is assumed
now). Before posting:

- Cut release v0.3, so the disks match the web build.
- Refresh the README's screenshots (they predate the text pass).

## Title (80 characters at most)

Show HN: Catwiz – a dice roguelike for the Apple IIe, in a Lisp compiler I wrote

Other options:

- Show HN: A dice roguelike for the 128K Apple IIe, written in my own 6502 Lisp
- Show HN: Tisple – a typed Lisp for the Apple II, and a roguelike made with it

## Link

https://wegfawefgawefg.github.io/tisple/play.html?game=catwiz

(HN wants the link to be the thing itself. The text goes in the first comment, or in the post's
text box.)

## Text

Catwiz is a dice roguelike for the 128K Apple IIe. You play a cat wizard. Each turn you roll
five dice whose six faces are your six item slots, and you play them on enemies through ten
fights to the Bulldog King. It runs in double hi-res with stereo Mockingboard music, ships on
two 5.25" disks, and takes a mouse. It plays in the browser above, on a phone too, or in
AppleWin or MAME, or on a real IIe from the disk images.

It's written in Tisple, a typed Lisp I made for the Apple II with its own optimising 6502
compiler. Raced against cc65, LLVM-MOS and Oscar64 on the same cycle-exact simulator, it is
the fastest on 13 small kernels. On 2,000 random programs it takes 0.80 of the best C
compiler's cycles (geometric mean). On ten program-shaped benchmarks it is about even with
Oscar64 (0.98), and it loses Dhrystone by 2x. Catwiz is about 29,000 lines of Tisple.

Some of the tricks it took to fit:

- The music keeps playing while the disk loads. The disk reader runs between the music's ticks,
  and the next song is read from disk while the current one fades.
- Screen code takes turns in one 3 KB region, copied in from aux memory or read from the second
  disk when a screen opens. The compiler works out the groups from the call graph.
- Cold code lives in the language card's hidden second 4 KB bank, called through stubs, and the
  songs now play from there too.
- Every face and charm is a one-sector record on disk 2, so the about 100 faces and 35 charms
  cost no memory.
- The browser player is a cycle-exact IIe in WebAssembly with its own boot ROM, so no Apple ROMs
  are shipped. Its drive sounds are synthesized from the emulated drive's own events.

Source: https://github.com/wegfawefgawefg/catwiz and https://github.com/wegfawefgawefg/tisple
