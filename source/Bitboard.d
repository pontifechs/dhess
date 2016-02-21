module dhess.Bitboard;

import dhess.Position;

alias Bitboard = ulong;

/*
a8 b8 c8 ... g8 h8
a7 b7 c7 ... g7 h7
a6 b6 c6 ... g6 h6
 .  .  . ...  .  .
 .  .  . ...  .  .
 .  .  . ...  .  .
a2 b2 c2 ... g2 h2
a1 b1 c1 ... g1 h1


In memory:
Most significant bit: a8
Least significant bit: h1
*/


// All bitboards representing single positions;
mixin(allPositions());

enum ALL = -1;

// Ranks
enum RANK_1 = A_1 | B_1 | C_1 | D_1 | E_1 | F_1 | G_1 | H_1;
enum RANK_2 = A_2 | B_2 | C_2 | D_2 | E_2 | F_2 | G_2 | H_2;
enum RANK_3 = A_3 | B_3 | C_3 | D_3 | E_3 | F_3 | G_3 | H_3;
enum RANK_4 = A_4 | B_4 | C_4 | D_4 | E_4 | F_4 | G_4 | H_4;
enum RANK_5 = A_5 | B_5 | C_5 | D_5 | E_5 | F_5 | G_5 | H_5;
enum RANK_6 = A_6 | B_6 | C_6 | D_6 | E_6 | F_6 | G_6 | H_6;
enum RANK_7 = A_7 | B_7 | C_7 | D_7 | E_7 | F_7 | G_7 | H_7;
enum RANK_8 = A_8 | B_8 | C_8 | D_8 | E_8 | F_8 | G_8 | H_8;

// Files
enum FILE_A = A_1 | A_2 | A_3 | A_4 | A_5 | A_6 | A_7 | A_8;
enum FILE_B = B_1 | B_2 | B_3 | B_4 | B_5 | B_6 | B_7 | B_8;
enum FILE_C = C_1 | C_2 | C_3 | C_4 | C_5 | C_6 | C_7 | C_8;
enum FILE_D = D_1 | D_2 | D_3 | D_4 | D_5 | D_6 | D_7 | D_8;
enum FILE_E = E_1 | E_2 | E_3 | E_4 | E_5 | E_6 | E_7 | E_8;
enum FILE_F = F_1 | F_2 | F_3 | F_4 | F_5 | F_6 | F_7 | F_8;
enum FILE_G = G_1 | G_2 | G_3 | G_4 | G_5 | G_6 | G_7 | G_8;
enum FILE_H = H_1 | H_2 | H_3 | H_4 | H_5 | H_6 | H_7 | H_8;

// Inverse
enum NOT_FILE_A = ALL.remove(FILE_A);
enum NOT_FILE_H = ALL.remove(FILE_H);

string allPositions()
{
  import std.stdio;
  import std.traits;

  auto ret = "";
  foreach(col; [EnumMembers!Column])
  {
    foreach (row; [EnumMembers!Row])
    {
      ret ~= buildPosition(col, row) ~"\n";
    }
  }
  return ret;
}

unittest
{
  assert(A_8 == 1UL << 63);
  assert(B_7 == 1UL << 54);
  assert(H_1 == 1UL);
  assert(NOT_FILE_A == (FILE_B | FILE_C | FILE_D | FILE_E | FILE_F | FILE_G | FILE_H));
  assert(NOT_FILE_H == (FILE_A | FILE_B | FILE_C | FILE_D | FILE_E | FILE_F | FILE_G));
}

string buildPosition(Column c, Row r)
{
  import std.conv;
  return "enum " ~ c.to!string ~ r.to!string ~ " = " ~ position(c, r).to!string ~ "UL;";
}
unittest
{
  assert(buildPosition(Column.A, Row._8) == "enum A_8 = 9223372036854775808UL;");
}


Bitboard position(Column c, Row r)
{
  return 1UL << (r * 8 + c);
}
unittest
{
  assert(position(Column.A, Row._8) == 1UL << 63);
  assert(position(Column.B, Row._8) == 1UL << 62);
  assert(position(Column.C, Row._8) == 1UL << 61);
  assert(position(Column.D, Row._8) == 1UL << 60);
  assert(position(Column.E, Row._8) == 1UL << 59);
  assert(position(Column.F, Row._8) == 1UL << 58);
  assert(position(Column.G, Row._8) == 1UL << 57);
  assert(position(Column.H, Row._8) == 1UL << 56);

  assert(position(Column.A, Row._7) == 1UL << 55);
  assert(position(Column.B, Row._7) == 1UL << 54);
  assert(position(Column.C, Row._7) == 1UL << 53);
  assert(position(Column.D, Row._7) == 1UL << 52);
  assert(position(Column.E, Row._7) == 1UL << 51);
  assert(position(Column.F, Row._7) == 1UL << 50);
  assert(position(Column.G, Row._7) == 1UL << 49);
  assert(position(Column.H, Row._7) == 1UL << 48);

  assert(position(Column.G, Row._2) == 1UL << 9);
  assert(position(Column.H, Row._1) == 1UL << 0);
}
unittest
{
  Bitboard a1 = A_1;
  Bitboard b2 = B_2;
  Bitboard both = a1 | b2;
}

void printHex(Bitboard board)
{
  import std.stdio;
  writefln("0x%.16X", board);
}

// Function pointers can't default the arguments
Bitboard north(Bitboard board)
{
  return north(board, 1);
}
Bitboard north(Bitboard board, int num)
{
  return board << 8 * num;
}
unittest
{
  assert(RANK_2.north == RANK_3);
  assert(RANK_2.north(2) == RANK_4);
  auto diag = A_8 | B_7 | C_6 | D_5 | E_4 | F_3 | G_2 | H_1;
  auto upOne = B_8 | C_7 | D_6 | E_5 | F_4 | G_3 | H_2;
  assert (diag.north == upOne);
  assert(RANK_8.north == 0L);
}

Bitboard south(Bitboard board)
{
  return south(board, 1);
}
Bitboard south(Bitboard board, int num)
{
  return board >> 8 * num;
}
unittest
{
  assert(RANK_3.south == RANK_2);
  assert(RANK_3.south(2) == RANK_1);
  auto diag = A_8 | B_7 | C_6 | D_5 | E_4 | F_3 | G_2 | H_1;
  auto dnOne = A_7 | B_6 | C_5 | D_4 | E_3 | F_2 | G_1;
  assert(diag.south == dnOne);
  assert(RANK_1.south == 0L);
}

Square LS1B(Bitboard board)
{
  asm
  {
    bsf RAX, board;
  }
}
unittest
{
  auto ends = A_7 | G_1;
  assert(ends.LS1B == 1);
  assert(A_8.LS1B == 63);
}

Square MS1B(Bitboard board)
{
  asm
  {
    bsr RAX, board;
  }
}
unittest
{
  auto ends = B_8 | G_1;
  assert(ends.MS1B == 62);
}

Bitboard resetLS1B(Bitboard board)
{
  return board & board-1;
}
unittest
{
  auto two = A_8 | H_1;
  assert(two.resetLS1B == A_8);
  assert(two.resetLS1B.resetLS1B == 0);
}

Square[] serialize(Bitboard board)
{
  import std.conv;
  Square[] ret;
  while (board)
  {
    ret ~= board.LS1B.to!Square;
    board = board.resetLS1B;
  }
  return ret;
}
unittest
{
  import std.algorithm;
  auto rank1 = RANK_1.serialize;
  assert(rank1 == [Square.H1,
                   Square.G1,
                   Square.F1,
                   Square.E1,
                   Square.D1,
                   Square.C1,
                   Square.B1,
                   Square.A1]);

  auto fileA = FILE_A.serialize;
  assert(fileA == [Square.A1,
                   Square.A2,
                   Square.A3,
                   Square.A4,
                   Square.A5,
                   Square.A6,
                   Square.A7,
                   Square.A8]);
}

Bitboard east(Bitboard board)
{
  return east(board, 1);
}
Bitboard east(Bitboard board, int amount)
{
  import std.stdio;
  Bitboard ret = 0L;
  auto places = board.serialize;
  foreach (index; places)
  {
    auto newIndex = index - amount;
    if ((index / 8) == (newIndex / 8))
    {
      ret |= (1L << newIndex);
    }
  }
  return ret;
}
unittest
{
  assert(A_8.east == B_8);
  auto two = A_8 | B_7;
  auto twoR = B_8 | C_7;
  assert(two.east == twoR);
  assert(H_8.east == 0);
}

Bitboard west(Bitboard board)
{
  return west(board, 1);
}
Bitboard west(Bitboard board, int amount = 1)
{
  import std.stdio;
  Bitboard ret = 0L;
  auto places = board.serialize;
  foreach (index; places)
  {
    auto newIndex = index + amount;
    if ((index / 8) == (newIndex / 8))
    {
      ret |= (1L << newIndex);
    }
  }
  return ret;
}
unittest
{
  assert(B_8.west == A_8);
  auto two = B_8 | C_7;
  auto twoR = A_8 | B_7;
  assert(two.west == twoR);
  assert(A_8.west == 0);
}

Bitboard remove(Bitboard lhs, Bitboard rhs)
{
  return lhs & ~rhs;
}
unittest
{
  auto rank1MinusA = B_1 | C_1 | D_1 | E_1 | F_1 | G_1 | H_1;
  assert(RANK_1.remove(A_1) == rank1MinusA);

  assert(RANK_1.remove(FILE_A) == rank1MinusA);
}

ubyte pop(Bitboard board)
{
  asm
  {
    popcnt RAX, board;
  }
}
unittest
{
  assert(RANK_1.pop == 8);
  assert(RANK_3.pop == 8);
  assert(RANK_5.pop == 8);
  assert(RANK_7.pop == 8);
  assert(A_1.pop == 1);
  assert((RANK_1 | FILE_A).pop == 15);
}


Bitboard northwest(Bitboard board)
{
  return (board << 9) & NOT_FILE_H;
}
unittest
{
  assert(B_1.northwest == A_2);
  assert(A_1.northwest == 0L);
  assert(B_8.northwest == 0L);
  assert((B_1 | A_2).northwest == A_2);
}


Bitboard northeast(Bitboard board)
{
  return (board << 7) & NOT_FILE_A;
}
unittest
{
  assert(A_1.northeast == B_2);
  assert(B_1.northeast == C_2);
  assert(H_1.northeast == 0L);
  assert(G_7.northeast == H_8);
  assert(H_7.northeast == 0L);
}

Bitboard southwest(Bitboard board)
{
  return (board >> 7) & NOT_FILE_H;
}
unittest
{
  assert(B_8.southwest == A_7);
  assert(A_8.southwest == 0L);
}


Bitboard southeast(Bitboard board)
{
  return (board >> 9) & NOT_FILE_A;
}
unittest
{
  assert(A_2.southeast == B_1);
  assert(H_2.southeast == 0L);
}


//TODO:: Make this not dumb7fill
Bitboard northSlide(Bitboard board)
{
  auto ret = board;
  ret |= ret.north;
  ret |= ret.north;
  ret |= ret.north;
  ret |= ret.north;
  ret |= ret.north;
  ret |= ret.north;
  ret |= ret.north;
  return ret;
}
unittest
{
  assert(D_4.northSlide == (D_4 | D_5 | D_6 | D_7 | D_8));
}

Bitboard southSlide(Bitboard board)
{
  auto ret = board;
  ret |= ret.south;
  ret |= ret.south;
  ret |= ret.south;
  ret |= ret.south;
  ret |= ret.south;
  ret |= ret.south;
  ret |= ret.south;
  return ret;
}
unittest
{
  assert(D_4.southSlide == (D_4 | D_3 | D_2 | D_1));
}

Bitboard eastSlide(Bitboard board)
{
  auto ret = board;
  ret |= ret.east;
  ret |= ret.east;
  ret |= ret.east;
  ret |= ret.east;
  ret |= ret.east;
  ret |= ret.east;
  ret |= ret.east;
  return ret;
}
unittest
{
  assert(D_4.eastSlide == (D_4 | E_4 | F_4 | G_4 | H_4));
}

Bitboard westSlide(Bitboard board)
{
  auto ret = board;
  ret |= ret.west;
  ret |= ret.west;
  ret |= ret.west;
  ret |= ret.west;
  ret |= ret.west;
  ret |= ret.west;
  ret |= ret.west;
  return ret;
}
unittest
{
  assert(D_4.westSlide == (D_4 | C_4 | B_4 | A_4));
}


Bitboard northeastSlide(Bitboard board)
{
  auto ret = board;
  ret |= ret.northeast;
  ret |= ret.northeast;
  ret |= ret.northeast;
  ret |= ret.northeast;
  ret |= ret.northeast;
  ret |= ret.northeast;
  ret |= ret.northeast;
  return ret;
}
unittest
{
  assert(D_4.northeastSlide == (D_4 | E_5 | F_6 | G_7 | H_8));
}

Bitboard northwestSlide(Bitboard board)
{
  auto ret = board;
  ret |= ret.northwest;
  ret |= ret.northwest;
  ret |= ret.northwest;
  ret |= ret.northwest;
  ret |= ret.northwest;
  ret |= ret.northwest;
  ret |= ret.northwest;
  return ret;
}
unittest
{
  assert(D_4.northwestSlide == (D_4 | C_5 | B_6 | A_7));
}

Bitboard southwestSlide(Bitboard board)
{
  auto ret = board;
  ret |= ret.southwest;
  ret |= ret.southwest;
  ret |= ret.southwest;
  ret |= ret.southwest;
  ret |= ret.southwest;
  ret |= ret.southwest;
  ret |= ret.southwest;
  return ret;
}
unittest
{
  assert(D_4.southwestSlide == (D_4 | C_3 | B_2 | A_1));
}

Bitboard southeastSlide(Bitboard board)
{
  auto ret = board;
  ret |= ret.southeast;
  ret |= ret.southeast;
  ret |= ret.southeast;
  ret |= ret.southeast;
  ret |= ret.southeast;
  ret |= ret.southeast;
  ret |= ret.southeast;
  return ret;
}
unittest
{
  assert(D_4.southeastSlide == (D_4 | E_3 | F_2 | G_1));
}

void printLong(Bitboard board)
{
  import std.stdio;
  ulong mask = 0xFF00000000000000;
  for (int i = 0; i < 8; ++i)
  {
    writefln("%.8b", (board&mask) >> 8*(7-i));
    mask = mask >> 8;
  }
  writeln();
}
