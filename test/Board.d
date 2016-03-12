import dhess.Bitboard;
import dhess.Board;
import dhess.Pieces;
import dhess.Move;
import dhess.Position;

import std.stdio;
import std.algorithm;
import std.array;

// Build from FEN
unittest
{
  Board board = Board();

  assert(board.boards[Color.White][Piece.Pawn] == RANK_2);
  assert(board.boards[Color.Black][Piece.Pawn] == RANK_7);
  assert(board.boards[Color.White][Piece.King] == E_1);
  assert(board.boards[Color.Black][Piece.King] == E_8);
  assert(board.boards[Color.White][Piece.Queen] == D_1);
  assert(board.boards[Color.Black][Piece.Queen] == D_8);
  assert(board.boards[Color.White][Piece.Bishop] == (C_1 | F_1));
  assert(board.boards[Color.Black][Piece.Bishop] == (C_8 | F_8));
  assert(board.boards[Color.White][Piece.Knight] == (B_1 | G_1));
  assert(board.boards[Color.Black][Piece.Knight] == (B_8 | G_8));
  assert(board.boards[Color.White][Piece.Rook] == (A_1 | H_1));
  assert(board.boards[Color.Black][Piece.Rook] == (A_8 | H_8));
}



// Pawn moves
unittest
{

  auto fen = "8/pppppppp/3P4/4P3/8/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.Black, Piece.Pawn));

  auto expected = sort([
    // Moves
    Move(Piece.Pawn, Square.A7, Square.A6),
    Move(Piece.Pawn, Square.A7, Square.A5),
    Move(Piece.Pawn, Square.B7, Square.B6),
    Move(Piece.Pawn, Square.B7, Square.B5),
    Move(Piece.Pawn, Square.C7, Square.C6),
    Move(Piece.Pawn, Square.C7, Square.C5),
    Move(Piece.Pawn, Square.E7, Square.E6),
    Move(Piece.Pawn, Square.F7, Square.F6),
    Move(Piece.Pawn, Square.F7, Square.F5),
    Move(Piece.Pawn, Square.G7, Square.G6),
    Move(Piece.Pawn, Square.G7, Square.G5),
    Move(Piece.Pawn, Square.H7, Square.H6),
    Move(Piece.Pawn, Square.H7, Square.H5),

    // Attacks
    Move(Piece.Pawn, Square.C7, Square.D6, Piece.Pawn, Square.D6),
    Move(Piece.Pawn, Square.E7, Square.D6, Piece.Pawn, Square.D6)
  ]);

  assert(actual == expected);
}

// Promotions
unittest
{
  import std.typecons;

  auto fen = "8/P7/8/8/8/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Pawn));

  auto expected = sort([
    Move(Piece.Pawn, Square.A7, Square.A8, Piece.None, Square.init, Piece.Queen),
    Move(Piece.Pawn, Square.A7, Square.A8, Piece.None, Square.init, Piece.Bishop),
    Move(Piece.Pawn, Square.A7, Square.A8, Piece.None, Square.init, Piece.Knight),
    Move(Piece.Pawn, Square.A7, Square.A8, Piece.None, Square.init, Piece.Rook)
  ]);
  assert(actual == expected);
}


unittest
{

  auto board = Board();

  auto actual = sort(board.moves!(Color.White, Piece.Pawn));

  auto expected = sort([
    Move(Piece.Pawn, Square.A2, Square.A3),
    Move(Piece.Pawn, Square.A2, Square.A4),
    Move(Piece.Pawn, Square.B2, Square.B3),
    Move(Piece.Pawn, Square.B2, Square.B4),
    Move(Piece.Pawn, Square.C2, Square.C3),
    Move(Piece.Pawn, Square.C2, Square.C4),
    Move(Piece.Pawn, Square.D2, Square.D3),
    Move(Piece.Pawn, Square.D2, Square.D4),
    Move(Piece.Pawn, Square.E2, Square.E3),
    Move(Piece.Pawn, Square.E2, Square.E4),
    Move(Piece.Pawn, Square.F2, Square.F3),
    Move(Piece.Pawn, Square.F2, Square.F4),
    Move(Piece.Pawn, Square.G2, Square.G3),
    Move(Piece.Pawn, Square.G2, Square.G4),
    Move(Piece.Pawn, Square.H2, Square.H3),
    Move(Piece.Pawn, Square.H2, Square.H4)
  ]);

  assert(actual == expected);
}

// Knights
unittest
{

  auto fen = "8/pppppppp/8/3N4/3N4/8/PPPPPPPP/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Knight));

  auto expected = sort([
    // knight on d5
    Move(Piece.Knight, Square.D5, Square.C7, Piece.Pawn, Square.C7),
    Move(Piece.Knight, Square.D5, Square.E7, Piece.Pawn, Square.E7),
    Move(Piece.Knight, Square.D5, Square.F6),
    Move(Piece.Knight, Square.D5, Square.F4),
    Move(Piece.Knight, Square.D5, Square.E3),
    Move(Piece.Knight, Square.D5, Square.C3),
    Move(Piece.Knight, Square.D5, Square.B4),
    Move(Piece.Knight, Square.D5, Square.B6),

    // Knight on d4
    Move(Piece.Knight, Square.D4, Square.C6),
    Move(Piece.Knight, Square.D4, Square.E6),
    Move(Piece.Knight, Square.D4, Square.F5),
    Move(Piece.Knight, Square.D4, Square.F3),
    Move(Piece.Knight, Square.D4, Square.B3),
    Move(Piece.Knight, Square.D4, Square.B5),
  ]);
}


// King
unittest
{

  auto fen = "8/8/2pP4/3K4/8/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.King));

  auto expected = sort([
    Move(Piece.King, Square.D5, Square.C6),
    Move(Piece.King, Square.D5, Square.E6),
    Move(Piece.King, Square.D5, Square.E5),
    Move(Piece.King, Square.D5, Square.E4),
    Move(Piece.King, Square.D5, Square.D4),
    Move(Piece.King, Square.D5, Square.C4),
    Move(Piece.King, Square.D5, Square.C5)
  ]);
}

// Rook
unittest
{

  auto fen = "8/3p4/8/3R4/3P4/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Rook));

  auto expected = sort([
    Move(Piece.Rook, Square.D5, Square.A5),
    Move(Piece.Rook, Square.D5, Square.B5),
    Move(Piece.Rook, Square.D5, Square.C5),
    Move(Piece.Rook, Square.D5, Square.D6),
    Move(Piece.Rook, Square.D5, Square.D7, Piece.Pawn, Square.D7),
    Move(Piece.Rook, Square.D5, Square.E5),
    Move(Piece.Rook, Square.D5, Square.F5),
    Move(Piece.Rook, Square.D5, Square.G5),
    Move(Piece.Rook, Square.D5, Square.H5),
  ]);

  assert(actual == expected);
}

// Bishop
unittest
{

  auto fen = "8/5p2/8/3B4/2P5/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Bishop));

  auto expected = sort([
    Move(Piece.Bishop, Square.D5, Square.A8),
    Move(Piece.Bishop, Square.D5, Square.B7),
    Move(Piece.Bishop, Square.D5, Square.C6),
    Move(Piece.Bishop, Square.D5, Square.E6),
    Move(Piece.Bishop, Square.D5, Square.F7, Piece.Pawn, Square.F7),
    Move(Piece.Bishop, Square.D5, Square.E4),
    Move(Piece.Bishop, Square.D5, Square.F3),
    Move(Piece.Bishop, Square.D5, Square.G2),
    Move(Piece.Bishop, Square.D5, Square.H1),
  ]);

  assert(actual == expected);
}



// Queen
unittest
{

  auto fen = "8/5p2/8/3Q4/2P5/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Queen));

  auto expected = sort([
    // Bishop-y
    Move(Piece.Queen, Square.D5, Square.A8),
    Move(Piece.Queen, Square.D5, Square.B7),
    Move(Piece.Queen, Square.D5, Square.C6),
    Move(Piece.Queen, Square.D5, Square.E6),
    Move(Piece.Queen, Square.D5, Square.F7, Piece.Pawn, Square.F7),
    Move(Piece.Queen, Square.D5, Square.E4),
    Move(Piece.Queen, Square.D5, Square.F3),
    Move(Piece.Queen, Square.D5, Square.G2),
    Move(Piece.Queen, Square.D5, Square.H1),
    // Rook-y
    Move(Piece.Queen, Square.D5, Square.A5),
    Move(Piece.Queen, Square.D5, Square.B5),
    Move(Piece.Queen, Square.D5, Square.C5),
    Move(Piece.Queen, Square.D5, Square.E5),
    Move(Piece.Queen, Square.D5, Square.F5),
    Move(Piece.Queen, Square.D5, Square.G5),
    Move(Piece.Queen, Square.D5, Square.H5),
    Move(Piece.Queen, Square.D5, Square.D1),
    Move(Piece.Queen, Square.D5, Square.D2),
    Move(Piece.Queen, Square.D5, Square.D3),
    Move(Piece.Queen, Square.D5, Square.D4),
    Move(Piece.Queen, Square.D5, Square.D6),
    Move(Piece.Queen, Square.D5, Square.D7),
    Move(Piece.Queen, Square.D5, Square.D8),
  ]);

  assert(actual == expected);
}

// All
unittest
{
  auto board = Board();
  auto actual = sort(board.moves!(Color.White));

  auto expected = sort([
    Move(Piece.Pawn, Square.A2, Square.A3),
    Move(Piece.Pawn, Square.A2, Square.A4),
    Move(Piece.Pawn, Square.B2, Square.B3),
    Move(Piece.Pawn, Square.B2, Square.B4),
    Move(Piece.Pawn, Square.C2, Square.C3),
    Move(Piece.Pawn, Square.C2, Square.C4),
    Move(Piece.Pawn, Square.D2, Square.D3),
    Move(Piece.Pawn, Square.D2, Square.D4),
    Move(Piece.Pawn, Square.E2, Square.E3),
    Move(Piece.Pawn, Square.E2, Square.E4),
    Move(Piece.Pawn, Square.F2, Square.F3),
    Move(Piece.Pawn, Square.F2, Square.F4),
    Move(Piece.Pawn, Square.G2, Square.G3),
    Move(Piece.Pawn, Square.G2, Square.G4),
    Move(Piece.Pawn, Square.H2, Square.H3),
    Move(Piece.Pawn, Square.H2, Square.H4),
    Move(Piece.Knight, Square.B1, Square.A3),
    Move(Piece.Knight, Square.B1, Square.C3),
    Move(Piece.Knight, Square.G1, Square.F3),
    Move(Piece.Knight, Square.G1, Square.H3),
  ]);

  assert(actual == expected);
}


// En Passant
unittest
{

  auto fen = "8/8/8/3Pp3/8/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Pawn));

  auto expected = sort([
    Move(Piece.Pawn, Square.D5, Square.D6)
  ]);

  assert(actual == expected);
}


// En Passant
unittest
{

  auto fen = "8/8/8/3PpP2/8/8/8/8 w KQkq e6 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Pawn));

  auto expected = sort([
    Move(Piece.Pawn, Square.D5, Square.D6),
    Move(Piece.Pawn, Square.F5, Square.F6),
    Move(Piece.Pawn, Square.D5, Square.E6, Piece.Pawn, Square.E5),
    Move(Piece.Pawn, Square.F5, Square.E6, Piece.Pawn, Square.E5)
  ]);

  assert(actual == expected);
}

// Castling all available
unittest
{
  auto fen = "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1";
  auto board = Board(fen);
  auto actualWhite = sort(board.moves!(Color.White, Piece.King));

  auto expectedWhite = sort([
    // Castling squares
    Move(Piece.King, Square.E1, Square.G1),
    Move(Piece.King, Square.E1, Square.C1),
    // Normal Squares
    Move(Piece.King, Square.E1, Square.D1),
    Move(Piece.King, Square.E1, Square.D2),
    Move(Piece.King, Square.E1, Square.E2),
    Move(Piece.King, Square.E1, Square.F1),
    Move(Piece.King, Square.E1, Square.F2),

  ]);

  assert(actualWhite == expectedWhite);

  auto actualBlack = sort(board.moves!(Color.Black, Piece.King));

  auto expectedBlack = sort([
    // Castling squares
    Move(Piece.King, Square.E8, Square.G8),
    Move(Piece.King, Square.E8, Square.C8),
    // Normal Squares
    Move(Piece.King, Square.E8, Square.D8),
    Move(Piece.King, Square.E8, Square.D7),
    Move(Piece.King, Square.E8, Square.E7),
    Move(Piece.King, Square.E8, Square.F8),
    Move(Piece.King, Square.E8, Square.F7),
  ]);

  assert(actualWhite == expectedWhite);
}

// Castling queenSide in check, kingSide OK
unittest
{
  auto fen = "r3k2r/8/8/6b1/6B1/8/8/R3K2R w KQkq - 0 1";
  auto board = Board(fen);
  auto actualWhite = sort(board.moves!(Color.White, Piece.King));

  auto expectedWhite = sort([
    // Castling squares
    Move(Piece.King, Square.E1, Square.G1),
    // Normal Squares
    Move(Piece.King, Square.E1, Square.D1),
    Move(Piece.King, Square.E1, Square.D2),
    Move(Piece.King, Square.E1, Square.E2),
    Move(Piece.King, Square.E1, Square.F1),
    Move(Piece.King, Square.E1, Square.F2),

  ]);

  assert(actualWhite == expectedWhite);

  auto actualBlack = sort(board.moves!(Color.Black, Piece.King));

  auto expectedBlack = sort([
    // Castling squares
    Move(Piece.King, Square.E8, Square.G8),
    // Normal Squares
    Move(Piece.King, Square.E8, Square.D8),
    Move(Piece.King, Square.E8, Square.D7),
    Move(Piece.King, Square.E8, Square.E7),
    Move(Piece.King, Square.E8, Square.F8),
    Move(Piece.King, Square.E8, Square.F7),
  ]);

  assert(actualWhite == expectedWhite);
}

// Serialize
unittest
{
  import dhess.FEN;
  auto start = Board();

  assert(start.serialize == START);
}

// Simple move
unittest
{
  import dhess.FEN;

  auto start = Board();

  start.move(Move(Piece.Pawn, Square.E2, Square.E4));
  auto e4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1";
  assert(start.serialize == e4);

  start.move(Move(Piece.Pawn, Square.E7, Square.E5));
  auto e6 = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2";
  assert(start.serialize == e6);
}


// Perft-revealed edge-cases =======================================================

// Can't en passant that reveals a check
unittest
{
  auto fen = "K7/8/8/8/1R3pPk/8/8/8 b - g3 0 1";
  auto board = Board(fen);
  auto illegal = Move(Piece.Pawn, Square.F4, Square.G3, Piece.Pawn, Square.G4);

  assert(!board.legal(illegal));
}

// Mistakenly returning not in check
unittest
{
  auto fen = "8/2p5/3p4/KP5r/1R3p1k/6P1/4P3/8 b - - 0 1";
  auto board = Board(fen);
  auto illegal = Move(Piece.Rook, Square.H5, Square.F5);
  auto actual = sort(board.moves().filter!(move => board.legal(move)).array);

  assert(!board.legal(illegal));
}

// Can't castle here (even if the FEN says you might be able to):
unittest
{
  auto fen = "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPPBN1PP/RN1QK2n w KQ - 0 8";
  auto board = Board(fen);
  auto castleKingside = Move(Piece.King, Square.E1, Square.G1);
  assert(!board.legal(castleKingside));
}

// Capturing a rook disallows castling for that side
unittest
{
  auto fen = "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPPBNnPP/RN1QK2R b KQ - 0 8";
  auto board = Board(fen);
  auto captureKingside = Move(Piece.Knight, Square.F2, Square.H1, Piece.Rook, Square.H1);
  board.move(captureKingside);
  assert(!board.castling[Color.White, Piece.King]);
}

// Should be able to castle here
unittest
{
  auto fen = "r3k2r/p1pNqpb1/bn2pnp1/3P4/1p2P3/2N2Q1p/PPPBBPPP/R3K2R b KQkq - 0 1";
  auto board = Board(fen);
  auto castleQueenside = Move(Piece.King, Square.E8, Square.C8);
  assert(board.legal(castleQueenside));
}

// Shouldn't be able to castle here, though
unittest
{
  auto fen = "rr2k2r/p1pNqpb1/bn2pnp1/3P4/1p2P3/2N2Q1p/PPPBBPPP/R3K2R b KQkq - 0 1";
  auto board = Board(fen);
  auto castleQueenside = Move(Piece.King, Square.E8, Square.C8);
  assert(!board.legal(castleQueenside));
}


// moving a rook disallows castling for that rook
unittest
{
  auto pos2FEN = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1";
  auto board = Board(pos2FEN);
  auto a1b1Move = Move(Piece.Rook, Square.A1, Square.B1);
  board.move(a1b1Move);
  assert(!board.castling[Color.White, Piece.Queen]);
  assert(board.castling[Color.White, Piece.King]);
}

// Castling updates the castling appropriately
unittest
{
  auto fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1";
  auto board = Board(fen);
  auto move = Move(Piece.King, Square.E1, Square.C1);
  board.move(move);
  assert(!board.castling[Color.White, Piece.King]);
  assert(!board.castling[Color.White, Piece.Queen]);
}

// Castling queenside moves the rook appropriately.
unittest
{
  auto pos2FEN = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1";
  auto e1c1 = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/2KR3R b kq - 1 1";
  auto board = Board(pos2FEN);
  auto move = Move(Piece.King, Square.E1, Square.C1);
  assert(move.isCastling);
  board.move(move);

  auto expectedRook = (1L << Square.D1);
  assert((board.boards[Color.White][Piece.Rook] & expectedRook) > 0);
}
