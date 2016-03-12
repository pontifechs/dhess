module dhess.test.Perft;


import dhess.Board;
import dhess.FEN;
import dhess.Position;
import dhess.Pieces;

import std.conv;
import std.stdio;
import std.algorithm;
import std.array;
import std.parallelism;

ulong perft(Board board, ulong depth)
{
  shared auto count = 0;

  // Base case
  if (depth == 0)
  {
    return 1;
  }
  if (depth == 1)
  {
    auto moves = board.moves.filter!(move => board.legal(move)).array;
    return moves.length;
  }
  else
  {
    auto moves = board.moves.filter!(move => board.legal(move)).array;
    foreach (move; moves)
    {
      // Copy the board
      Board cp = board;

      // Make the move
      cp.move(move);

      // Recurse
      auto perft = perft(cp, depth - 1);
      core.atomic.atomicOp!"+="(count, perft); // Count addition needs to be atomic
    }
    return count;
  }
}


void runPerft(FEN start, ulong[] values)
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
  import std.datetime;

  // traditional:
  /*
  writeln(Clock.currTime());
  //runPerft(START, [20, 400, 8_902, 197_281, 4_865_609, 119_060_324, 3_195_901_860, 84_998_978_956]);
  runPerft(START, [20, 400, 8_902, 197_281, 4_865_609, 119_060_324]);
  writeln(Clock.currTime());
  writeln("Traditional Complete!");

  writeln(Clock.currTime());
  pos2();
  writeln("Pos2 Complete!");

  writeln(Clock.currTime());
  pos3();
  writeln("Pos3 Complete!");

  writeln(Clock.currTime());
  pos4();
  writeln("Pos4 Complete!");

  writeln(Clock.currTime());
  pos5();
  writeln("Pos5 Complete!");

  writeln(Clock.currTime());
  pos6();
  writeln("Pos6 Complete!");
  */
  auto board = Board();
  stockfish(board, 5);
}

// Kiwipete
void pos2()
{
  import dhess.Move;
  import dhess.Pieces;
  import dhess.Position;

  auto pos2FEN = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1";
  runPerft(pos2FEN, [48, 2_039, 97_862, 4_085_603, 193_690_690]);
}

void pos3()
{
  auto pos3FEN = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1";
  runPerft(pos3FEN, [14, 191, 2812, 43_238, 674_624, 11_030_083, 178_633_661]);

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

void pos4()
{
  auto fen = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1";
  runPerft(fen, [6, 264, 9_467, 422_333, 15_833_292, 706_045_033]);
}

void pos5()
{
  auto fen = "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8";
  runPerft(fen, [44, 1_486, 62_379, 2_103_487, 89_941_194]);
}

void pos6()
{
  auto fen = "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10";
  runPerft(fen, [46,
                 2_079,
                 89_890,
                 3_894_594,
                 164_075_551,
                 6_923_051_137,
                 287_188_994_746,
                 11_923_589_843_527,
                 490_154_852_788_714
             ]);
}

// Useful for comparing results to stockfish's perft
void stockfish(Board board, int depth = 1)
{
  import std.algorithm;
  import std.array;

  auto moves = board.moves.filter!(
    move => board.legal(move)
  ).array;

  foreach(move; moves)
  {
    Board cp = board;
    cp.move(move);
    writeln(move.source, move.destination, ": ", perft(cp, depth - 1));
  }
}
