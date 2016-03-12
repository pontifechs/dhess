
/**
 * a standalone magic bitboard finder. Ported directly from:
 * http://hxhl95.github.io/magic-bitboards-chess/
 */

import std.stdio;
import std.conv;
import std.math;

ulong[64] ROOK_OCC_MASKS;
ulong[64] BISHOP_OCC_MASKS;


ulong genRand()
{
  import std.random;
  ulong n1 = uniform(0, 65536) & 0xFFFFUL;
  ulong n2 = uniform(0, 65536) & 0xFFFFUL;
  ulong n3 = uniform(0, 65536) & 0xFFFFUL;
  ulong n4 = uniform(0, 65536) & 0xFFFFUL;
  return (n1 << 48) | (n2 << 32) | (n3 << 16) | n4;
}

ulong genRandMagic()
{
  return genRand() & genRand() & genRand();
}

void getSetBits(ulong mask, ref ulong[] idxs)
{
  import core.bitop;
  while(mask != 0)
  {
    idxs ~= bsf(mask);
    mask &= (mask - 1);
  }
}

void genOccupancies(ref ulong[] idxs, ref ulong[] occs)
{
  ulong nbits = idxs.length, nmax = 1 << nbits;
  for (int i = 0; i < nmax; i++)
  {
    ulong occ = 0;
    for (int c = 0; c < nbits; c++)
    {
      if ((i >> c) & 1)
      {
        occ |= 1UL << idxs[c];
      }
    }
    occs ~= occ;
  }

}

ulong genBishopAttack(int pos, ulong occ)
{
    ulong res = 0, init = 1UL << pos;
    for (ulong m = init; res ^= m, m & 0x7F7F7F7F7F7F7F7FUL; m <<= 9)
        if (occ & m) break;
    for (ulong m = init; res ^= m, m & 0xFEFEFEFEFEFEFEFEUL; m <<= 7)
        if (occ & m) break;
    for (ulong m = init; res ^= m, m & 0xFEFEFEFEFEFEFEFEUL; m >>= 9)
        if (occ & m) break;
    for (ulong m = init; res ^= m, m & 0x7F7F7F7F7F7F7F7FUL; m >>= 7)
        if (occ & m) break;
    return res;
}

ulong genRookAttack(int pos, ulong occ)
{
  ulong res = 0, init = 1UL << pos;
  for (ulong m = init; res ^= m, m; m >>= 8)
    if (occ & m) break;
  for (ulong m = init; res ^= m, m; m <<= 8)
    if (occ & m) break;
  for (ulong m = init; res ^= m, m & 0x7F7F7F7F7F7F7F7FUL; m <<= 1)
    if (occ & m) break;
  for (ulong m = init; res ^= m, m & 0xFEFEFEFEFEFEFEFEUL; m >>= 1)
    if (occ & m) break;
  return res;
}

ulong genOccupanciesMask(ulong atk, int pos)
{
  if ((pos & 7) != 0)
    atk &= ~0x0101010101010101UL;
  if ((pos >> 3) != 0)
    atk &= ~0x00000000000000FFUL;
  if ((pos & 7) != 7)
    atk &= ~0x8080808080808080UL;
  if ((pos >> 3) != 7)
    atk &= ~0xFF00000000000000UL;
  return atk;
}

bool isMagic(ulong magic, ulong nbits, ref ulong[] occs, ref ulong[] atks, ref ulong[] lookup)
{
  lookup[] = -1;

  for (uint i = 0; i < occs.length; i++)
  {
    ulong magicIdx = (occs[i] * magic) >> (64 - nbits);
    if (lookup[magicIdx] == -1)
    {
      lookup[magicIdx] = atks[i];
    }
    else if (lookup[magicIdx] != atks[i])
    {
      return false;
    }
  }
  return true;
}


void main()
{
  ulong[64] rNBits;
  ulong[][64] rIdxs;
  ulong[][64] rOccs;
  ulong[][64] rAtks;
  ulong[64] bNBits;
  ulong[][64] bIdxs;
  ulong[][64] bOccs;
  ulong[][64] bAtks;

  ulong[] lookup = new ulong[4096];

  // Precompute
  for (int i = 0; i < 64; i++)
  {
    ROOK_OCC_MASKS[i] = genOccupanciesMask(genRookAttack(i, 0), i);
    BISHOP_OCC_MASKS[i] = genOccupanciesMask(genBishopAttack(i, 0), i);

    getSetBits(ROOK_OCC_MASKS[i], rIdxs[i]);
    getSetBits(BISHOP_OCC_MASKS[i], bIdxs[i]);
    rNBits[i] = rIdxs[i].length;
    bNBits[i] = bIdxs[i].length;

    genOccupancies(rIdxs[i], rOccs[i]);
    genOccupancies(bIdxs[i], bOccs[i]);

    for (uint j = 0; j < rOccs[i].length; j++)
      rAtks[i] ~= genRookAttack(i, rOccs[i][j]);
    for (uint j = 0; j < bOccs[i].length; j++)
      bAtks[i] ~= genBishopAttack(i, bOccs[i][j]);

  }

  writeln("-------------");
  for (int i = 0; i < 64; i++)
  {
    int ct = 0;
    while(true)
    {
      ulong testmagic = genRandMagic();
      if (isMagic(testmagic, rNBits[i], rOccs[i], rAtks[i], lookup))
      {
        writef("0x%.16X ", testmagic);
        writeln(ct);
        break;
      }
      ct++;
      if (ct == 1_000_000)
      {
        writefln("fail");
        break;
      }
    }
  }

  writeln("-------------");
  for (int i = 0; i < 64; i++)
  {
    int ct = 0;
    while(true)
    {
      ulong testmagic = genRandMagic();
      if (isMagic(testmagic, rNBits[i], rOccs[i], rAtks[i], lookup))
      {
        writef("0x%.16X ", testmagic);
        writeln(ct);
        break;
      }
      ct++;
      if (ct == 1_000_000)
      {
        writefln("fail");
        break;
      }
    }
  }
}

