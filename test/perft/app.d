module dhess.test.Perft;


import dhess.Board;
import dhess.FEN;

import std.conv;
import std.stdio;


int perft(Board board, ulong depth)
{
  auto count = 0;

  // Base case
  if (depth == 1)
  {
    auto moves = board.moves;
    foreach (move; moves)
    {
      if (board.legal(move))
      {
        count++;
      }
    }
    return count;
  }
  else
  {
    auto moves = board.moves;
    foreach (move; moves)
    {
      if (board.legal(move))
      {
        // Copy the board
        Board cp = board;
        // Make the move
        cp.move(move);
        // Recurse
        count += perft(cp, depth - 1);
      }
    }
    return count;
  }
}


void runPerft(FEN start, int[] values)
{
  auto board = Board(start);

  foreach (i, expected; values)
  {
    auto actual = perft(board, i + 1);
    if (actual != expected)
    {
      writeln("----------------------------------------");
      writeln("Perft failure for: " ~ start);
      writeln("Depth: " ~ (i + 1).to!string);
      writeln("Expected: " ~ expected.to!string);
      writeln("Got: " ~ actual.to!string);
      return;
    }
  }
}

void main()
{
  // traditional:
  // runPerft(START, [20, 400, 8_902]);

  // position 3:
  auto pos3FEN = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1";
  //runPerft(pos3FEN, [14, 191, 2812, 43_238]);

  auto rookCheck = "8/2p5/3p4/KP5r/5R1k/8/4P1P1/8 b - - 0 1";
  runPerft(rookCheck, [2]);
  auto pawnCheck = "8/2p5/3p4/KP5r/1R3p1k/6P1/4P3/8 b - - 0 1";
  runPerft(pawnCheck, [4]);

  auto gEnPassant = "8/2p5/3p4/KP5r/1R3pPk/8/4P3/8 b - g3 0 1";
  // Pawns: 4
  // King: 4
  // Rook: 9
  runPerft(gEnPassant, [17]);
  auto eEnPassant = "8/2p5/3p4/KP5r/1R2Pp1k/8/6P1/8 b - e3 0 1";
  // Pawns: 4
  // King: 3
  // Rook: 9
  runPerft(eEnPassant, [16]);

  auto rookSouthOne = "8/2p5/3p4/KP5r/5p1k/1R6/4P1P1/8 b - - 0 1";
  // Pawns: 4 (f4 isn't pinned anymore)
  // King: 2 (h3 and g3 are in check)
  // Rook: 9
  runPerft(rookSouthOne, [15]);


  auto rookSouthTwo = "8/2p5/3p4/KP5r/5p1k/8/1R2P1P1/8 b - - 0 1";
  // Pawns: 4 (f4 isn't pinned anymore)
  // King: 3 (h3 is check)
  // Rook: 9
  runPerft(rookSouthTwo, [16]);

  auto rookSouthThree = "8/2p5/3p4/KP5r/5p1k/8/4P1P1/1R6 b - - 0 1";
  runPerft(rookSouthThree, [16]);

  // Non interfering moves from white
  // Pawns: 3 (f4 is pinned)
  // King: 3 (h3 is check)
  // Rook: 9
  auto kingNorth = "8/2p5/K2p4/1P5r/1R3p1k/8/4P1P1/8 b - - 0 1";
  runPerft(kingNorth, [15]);

  auto kingSouth = "8/2p5/3p4/1P5r/KR3p1k/8/4P1P1/8 b - - 0 1";
  runPerft(kingSouth, [15]);

  auto rookEast1 = "8/2p5/3p4/KP5r/2R2p1k/8/4P1P1/8 b - - 0 1";
  runPerft(rookEast1, [15]);
  auto rookEast2 = "8/2p5/3p4/KP5r/3R1p1k/8/4P1P1/8 b - - 0 1";
  runPerft(rookEast2, [15]);
  auto rookEast3 = "8/2p5/3p4/KP5r/4Rp1k/8/4P1P1/8 b - - 0 1";
  runPerft(rookEast3, [15]);
  auto rookWest = "8/2p5/3p4/KP5r/R4p1k/8/4P1P1/8 b - - 0 1";
  runPerft(rookWest, [15]);
  auto pawnEPush = "8/2p5/3p4/KP5r/1R3p1k/4P3/6P1/8 b - - 0 1";
  runPerft(pawnEPush, [15]);





}

