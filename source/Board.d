module dhess.Board;

import dhess.Pieces;
import dhess.Position;
import dhess.Bitboard;
import dhess.FEN;
import dhess.Move;

import std.conv;

struct Board
{
  Bitboard[6][2] boards;


  static Board opCall(FEN fen = START)
  {
    import std.traits;
    Board b;

    auto lines = fen.parseBoard;
    foreach(col; [EnumMembers!Column])
    {
      foreach (row; [EnumMembers!Row])
      {
        auto piece = lines[row][col];
        if (piece.isNull)
        {
          continue;
        }
        auto pos = position(col, row);
        b.boards[piece.color][piece.piece] |= pos;
      }
    }
    return b;
  }

private:
  Bitboard all()
  {
    return all!(Color.White) | all!(Color.Black);
  }

  Bitboard empty()
  {
    return ~all();
  }

  Bitboard all(Color c)()
  {
    auto all = 0L;
    foreach (b; boards[c])
    {
      all |= b;
    }
    return all;
  }

  Bitboard enemy(Color c)()
  {
    return all!(not!c);
  }


public:

  // Pawns -------------------------------------------------------------------------------------------
  Move[] moves(Color color, Piece piece)()
    if (piece == Piece.Pawn)
  {
    enum pushDirection = (color == Color.White) ? 8 : -8;
    enum westAttackDirection = (color == Color.White) ? 9 : -7;
    enum eastAttackDirection = (color == Color.White) ? 7 : -9;

    Move[] ret = [];

    // Single pushes
    static if (color == Color.White)
    {
      auto singles = (boards[color][piece].north & empty).remove(RANK_8);
    }
    else
    {
      auto singles = (boards[color][piece].south & empty).remove(RANK_1);
    }

    // Double pushes
    static if (color == Color.White)
    {
      auto doubles = (singles & RANK_3).north & empty;
    }
    else
    {
      auto doubles = (singles & RANK_6).south & empty;
    }


    while (singles > 0)
    {
      auto sq = singles.LS1B;
      ret ~= Move(Piece.Pawn, (sq - pushDirection).to!Square, sq);
      singles = singles.resetLS1B;
    }

    while (doubles > 0)
    {
      auto sq = doubles.LS1B;
      ret ~= Move(Piece.Pawn, (sq - 2*pushDirection).to!Square, sq);
      doubles = doubles.resetLS1B;
    }


    // Attacks
    static if (color == Color.White)
    {
      auto westAttacks = boards[color][piece].northwest & enemy!color;
      auto eastAttacks = boards[color][piece].northeast & enemy!color;
    }
    else
    {
      auto westAttacks = boards[color][piece].southwest & enemy!color;
      auto eastAttacks = boards[color][piece].southeast & enemy!color;
    }

    // West attacks
    while (westAttacks > 0)
    {

      auto sq = westAttacks.LS1B;
      ret ~= Move(Piece.Pawn, (sq - westAttackDirection).to!Square, sq);
      westAttacks = westAttacks.resetLS1B;
    }

    // east attacks
    while (eastAttacks > 0)
    {
      auto sq = eastAttacks.LS1B;
      ret ~= Move(Piece.Pawn, (sq - eastAttackDirection).to!Square, sq);
      eastAttacks = eastAttacks.resetLS1B;
    }


    // Pawn promotions
    static if (color == Color.White)
    {
      auto promotions = (boards[color][piece].north & empty & RANK_8);
    }
    else
    {
      auto promotions = (boards[color][piece].south & empty & RANK_1);
    }

    while (promotions > 0)
    {
      auto sq = promotions.LS1B;
      ret ~= Move(Piece.Pawn, (sq - pushDirection).to!Square, sq, Piece.Queen);
      ret ~= Move(Piece.Pawn, (sq - pushDirection).to!Square, sq, Piece.Bishop);
      ret ~= Move(Piece.Pawn, (sq - pushDirection).to!Square, sq, Piece.Knight);
      ret ~= Move(Piece.Pawn, (sq - pushDirection).to!Square, sq, Piece.Rook);
      promotions = promotions.resetLS1B;
    }

    return ret;
  }

  // Knights ---------------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)()
    if (p == Piece.Knight)
  {
    Move[] ret = [];

    auto knights = boards[c][p];
    while (knights > 0)
    {
      auto source = knights.LS1B;
      Bitboard knight = (1L << source);
      auto knightMoves = (knight.northeast.north |
                          knight.northeast.east |
                          knight.southeast.east |
                          knight.southeast.south |
                          knight.southwest.south |
                          knight.southwest.west |
                          knight.northwest.west |
                          knight.northwest.north) & (empty | enemy!c);

      while (knightMoves > 0)
      {
        auto dest = knightMoves.LS1B;
        ret ~= Move(Piece.Knight, source, dest);
        knightMoves = knightMoves.resetLS1B;
      }

      knights = knights.resetLS1B;
    }

    return ret;
  }

  // King ---------------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)()
    if (p == Piece.King)
  {
    Move[] ret = [];

    auto king = boards[c][p];
    auto source = king.LS1B;

    auto possible = (king.north |
                     king.northeast |
                     king.east |
                     king.southeast |
                     king.south |
                     king.southwest |
                     king.west |
                     king.northwest) & (empty | enemy!c);

    while (possible > 0)
    {
      auto sq = possible.LS1B;
      ret ~= Move(Piece.King, source, sq);
      possible = possible.resetLS1B;
    }

    return ret;
  }
  // Sliding -------------------------------------------------------------------
  alias MoveBitboard = Bitboard function(Bitboard);
  Bitboard marchMoves(Bitboard board, MoveBitboard move)
  {
    auto moves = 0L;
    auto march = board;
    for (int i = 0; i < 7; ++i)
    {
      march = move(march);
      march = march.remove(march & all);
      moves |= march;
    }
    return moves;
  }

  Bitboard marchCollisions(Bitboard board, MoveBitboard move)
  {
    auto attacks = 0L;
    auto march = board;
    for (int i = 0; i < 7; ++i)
    {
      march = move(march);
      attacks |= march & all;
      march = march.remove(march & all);
    }
    return attacks;
  }


  // Rooks ---------------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)()
    if (p == Piece.Rook)
  {
    Move[] ret = [];

    auto rooks = boards[c][p];

    while (rooks > 0)
    {
      auto sq = rooks.LS1B;
      Bitboard rook = (1L << sq);

      auto moves = marchMoves(rook, &north) |
        marchMoves(rook, &east) |
        marchMoves(rook, &south) |
        marchMoves(rook, &west);

      auto attacks = (marchCollisions(rook, &north) |
                      marchCollisions(rook, &east) |
                      marchCollisions(rook, &south) |
                      marchCollisions(rook, &west)) & enemy!c;

      auto all = moves | attacks;
      while (all > 0)
      {
        auto dest = all.LS1B;
        ret ~= Move(Piece.Rook, sq, dest);
        all = all.resetLS1B;
      }

      rooks = rooks.resetLS1B;
    }

    return ret;
  }


  // Bishops ----------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)()
    if (p == Piece.Bishop)
  {
    Move[] ret = [];

    auto bishops = boards[c][p];

    while (bishops > 0)
    {
      auto source = bishops.LS1B;
      auto bishop = (1L << source);

      auto moves = marchMoves(bishop, &northeast) |
        marchMoves(bishop, &southeast) |
        marchMoves(bishop, &southwest) |
        marchMoves(bishop, &northwest);

      auto attacks = (marchCollisions(bishop, &northeast) |
                      marchCollisions(bishop, &southeast) |
                      marchCollisions(bishop, &southwest) |
                      marchCollisions(bishop, &northwest)) & enemy!c;
      auto all = moves | attacks;

      while (all > 0)
      {
        auto dest = all.LS1B;
        ret ~= Move(Piece.Bishop, source, dest);
        all = all.resetLS1B;
      }

      bishops = bishops.resetLS1B;
    }

    return ret;
  }

  // Queens --------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)()
    if (p == Piece.Queen)
  {
    Move[] ret = [];

    auto queens = boards[c][p];

    while (queens > 0)
    {
      auto source = queens.LS1B;
      auto queen = (1L << source);

      auto moves = marchMoves(queen, &north) |
        marchMoves(queen, &northeast) |
        marchMoves(queen, &east) |
        marchMoves(queen, &southeast) |
        marchMoves(queen, &south) |
        marchMoves(queen, &southwest) |
        marchMoves(queen, &west) |
        marchMoves(queen, &northwest);

      auto collisions = (marchCollisions(queen, &north) |
                         marchCollisions(queen, &northeast) |
                         marchCollisions(queen, &east) |
                         marchCollisions(queen, &southeast) |
                         marchCollisions(queen, &south) |
                         marchCollisions(queen, &southwest) |
                         marchCollisions(queen, &west) |
                         marchCollisions(queen, &northwest)) & enemy!c;

      auto all = moves | collisions;

      while (all > 0)
      {
        auto dest = all.LS1B;
        ret ~= Move(Piece.Queen, source, dest);
        all = all.resetLS1B;
      }

      queens = queens.resetLS1B;
    }

    return ret;
  }

  // All --------------------------------------------------------------------------------------
  Move[] moves(Color c)()
  {
    return moves!(c, Piece.Pawn) ~
      moves!(c, Piece.Knight) ~
      moves!(c, Piece.King) ~
      moves!(c, Piece.Bishop) ~
      moves!(c, Piece.Rook) ~
      moves!(c, Piece.Queen);
  }
}

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

//  all black/all white
unittest
{
  Board board = Board();

  assert(board.all!(Color.Black) == (RANK_7 | RANK_8));
  assert(board.all!(Color.White) == (RANK_1 | RANK_2));
  assert(board.all == (board.all!(Color.Black) | board.all!(Color.White)));
}

// Empty
unittest
{
  Board board = Board();

  assert(board.empty == (RANK_3 | RANK_4 | RANK_5 | RANK_6));
}

// Pawn moves
unittest
{
  import std.algorithm;

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
    Move(Piece.Pawn, Square.C7, Square.D6),
    Move(Piece.Pawn, Square.E7, Square.D6)
  ]);

  assert(actual == expected);
}

// Promotions
unittest
{
  import std.algorithm;

  auto fen = "8/P7/8/8/8/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Pawn));

  auto expected = sort([
    Move(Piece.Pawn, Square.A7, Square.A8, Piece.Queen),
    Move(Piece.Pawn, Square.A7, Square.A8, Piece.Bishop),
    Move(Piece.Pawn, Square.A7, Square.A8, Piece.Knight),
    Move(Piece.Pawn, Square.A7, Square.A8, Piece.Rook)
  ]);

  assert(actual == expected);
}


unittest
{
  import std.algorithm;

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
  import std.algorithm;

  auto fen = "8/pppppppp/8/3N4/3N4/8/PPPPPPPP/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Knight));

  auto expected = sort([
    // knight on d5
    Move(Piece.Knight, Square.D5, Square.C7),
    Move(Piece.Knight, Square.D5, Square.E7),
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
  import std.algorithm;

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
  import std.algorithm;

  auto fen = "8/3p4/8/3R4/3P4/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Rook));

  auto expected = sort([
    Move(Piece.Rook, Square.D5, Square.A5),
    Move(Piece.Rook, Square.D5, Square.B5),
    Move(Piece.Rook, Square.D5, Square.C5),
    Move(Piece.Rook, Square.D5, Square.D6),
    Move(Piece.Rook, Square.D5, Square.D7),
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
  import std.algorithm;

  auto fen = "8/5p2/8/3B4/2P5/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Bishop));

  auto expected = sort([
    Move(Piece.Bishop, Square.D5, Square.A8),
    Move(Piece.Bishop, Square.D5, Square.B7),
    Move(Piece.Bishop, Square.D5, Square.C6),
    Move(Piece.Bishop, Square.D5, Square.E6),
    Move(Piece.Bishop, Square.D5, Square.F7),
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
  import std.algorithm;

  auto fen = "8/5p2/8/3Q4/2P5/8/8/8 w KQkq - 0 1";
  auto board = Board(fen);
  auto actual = sort(board.moves!(Color.White, Piece.Queen));

  auto expected = sort([
    // Bishop-y
    Move(Piece.Queen, Square.D5, Square.A8),
    Move(Piece.Queen, Square.D5, Square.B7),
    Move(Piece.Queen, Square.D5, Square.C6),
    Move(Piece.Queen, Square.D5, Square.E6),
    Move(Piece.Queen, Square.D5, Square.F7),
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
  import std.algorithm;

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


