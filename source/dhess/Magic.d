module dhess.Magic;


import dhess.Bitboard;
import dhess.Position;

import std.conv;
import std.math;

// Masks for extracting only the relevant bits to the magic, indexed by Square
Bitboard[64] OrthogonalRays;
Bitboard[64] DiagonalRays;

// Every possible occupancy state for the above masks, indexed by Square. Not needed after magics are computed.
private Bitboard[][64] OrthogonalOccupancies;
private Bitboard[][64] DiagonalOccupancies;

// Correct attack results for the above occupancy states, indexed by Square. Not needed after magics are computed.
private Bitboard[][64] OrthogonalAttacks;
private Bitboard[][64] DiagonalAttacks;

// Magic numbers, indexed by Square
Bitboard[64] OrthogonalMagics;
Bitboard[64] DiagonalMagics;

// Move database, indexed by Square and Magic (tm)
Bitboard[][64] OrthogonalDatabase;
Bitboard[][64] DiagonalDatabase;

// Credit for finally getting this concept through my thick skull, and for the general 
// approach I took goes here: http://hxhl95.github.io/magic-bitboards-chess/

private bool isMagic(ulong magic, ulong nbits, ref ulong[] occs, ref ulong[] atks, ref ulong[] lookup)
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

ulong genRand()
{
  import std.random;
  return uniform(0, 0xFFFFFFFFFFFFFFFFUL);
}

ulong genRandMagic()
{
  return genRand() & genRand() & genRand();
}

private Bitboard genBishopAttack(Square pos, ulong occ)
{
    Bitboard res = 0, init = 1UL << pos;
    for (Bitboard m = init; res ^= m, m & 0x7F7F7F7F7F7F7F7FUL; m <<= 9)
        if (occ & m) break;
    for (Bitboard m = init; res ^= m, m & 0xFEFEFEFEFEFEFEFEUL; m <<= 7)
        if (occ & m) break;
    for (Bitboard m = init; res ^= m, m & 0xFEFEFEFEFEFEFEFEUL; m >>= 9)
        if (occ & m) break;
    for (Bitboard m = init; res ^= m, m & 0x7F7F7F7F7F7F7F7FUL; m >>= 7)
        if (occ & m) break;
    return res;
}

private Bitboard genRookAttack(int pos, Bitboard occ)
{
  Bitboard res = 0, init = 1UL << pos;
  for (Bitboard m = init; res ^= m, m; m >>= 8)
    if (occ & m) break;
  for (Bitboard m = init; res ^= m, m; m <<= 8)
    if (occ & m) break;
  for (Bitboard m = init; res ^= m, m & 0x7F7F7F7F7F7F7F7FUL; m <<= 1)
    if (occ & m) break;
  for (Bitboard m = init; res ^= m, m & 0xFEFEFEFEFEFEFEFEUL; m >>= 1)
    if (occ & m) break;
  return res;
}


static this()
{
  import std.traits;

  foreach (col; [EnumMembers!Column])
  {
    foreach(row; [EnumMembers!Row])
    {
      auto sq = square(row, col);
      auto squareBoard = (1UL << sq);

      auto orthog = squareBoard.northSlide |
        squareBoard.eastSlide |
        squareBoard.southSlide |
        squareBoard.westSlide;

      if (row != Row._1)
      {
        orthog = orthog.remove(RANK_1);
      }
      if (row != Row._8)
      {
        orthog = orthog.remove(RANK_8);
      }
      if (col != Column.A)
      {
        orthog = orthog.remove(FILE_A);
      }
      if (col != Column.H)
      {
        orthog = orthog.remove(FILE_H);
      }
      orthog = orthog.remove(squareBoard);
      OrthogonalRays[sq] = orthog;
      OrthogonalOccupancies[sq] = orthog.subsets;

      auto diag = squareBoard.northeastSlide |
        squareBoard.southeastSlide |
        squareBoard.southwestSlide |
        squareBoard.northwestSlide;
      diag = diag.remove(RANK_1);
      diag = diag.remove(RANK_8);
      diag = diag.remove(FILE_A);
      diag = diag.remove(FILE_H);
      diag = diag.remove(squareBoard);
      DiagonalRays[sq] = diag;
      DiagonalOccupancies[sq] = diag.subsets;
    }
  }


  // Precompute correct attacks for each occupancy state.
  foreach (sq; [EnumMembers!Square])
  {
    for (uint j = 0; j < OrthogonalOccupancies[sq].length; j++)
      OrthogonalAttacks[sq] ~= genRookAttack(sq, OrthogonalOccupancies[sq][j]);
    for (uint j = 0; j < DiagonalOccupancies[sq].length; j++)
      DiagonalAttacks[sq] ~= genBishopAttack(sq, DiagonalOccupancies[sq][j]);
  }

  // Find Rook magics
  for (int i = 0; i < 64; i++)
  {
    auto bits = OrthogonalRays[i].serialize.length;
    ulong[] lookup = new ulong[pow(2, bits)];
    int ct = 0;
    while(true)
    {
      ulong testmagic = genRandMagic();
      if (isMagic(testmagic,
                  bits,
                  OrthogonalOccupancies[i],
                  OrthogonalAttacks[i],
                  lookup))
      {
        OrthogonalMagics[i] = testmagic;
        OrthogonalDatabase[i] = lookup;
        break;
      }
      ct++;
      if (ct == 1_000_000)
      {
        throw new Exception("Failed to find a rook magic for " ~ i.to!Square.to!string);
      }
    }
  }

  // Find Bishop magics
  for (int i = 0; i < 64; i++)
  {
    auto bits = DiagonalRays[i].serialize.length;
    ulong[] lookup = new ulong[pow(2, bits)];
    int ct = 0;
    while(true)
    {
      ulong testmagic = genRandMagic();
      if (isMagic(testmagic,
                  bits,
                  DiagonalOccupancies[i],
                  DiagonalAttacks[i],
                  lookup))
      {
        DiagonalMagics[i] = testmagic;
        DiagonalDatabase[i] = lookup;
        break;
      }
      ct++;
      if (ct == 1_000_000)
      {
        throw new Exception("Failed to find a bishop magic for " ~ i.to!Square.to!string);
      }
    }
  }
}
