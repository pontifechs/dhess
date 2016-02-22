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

  Color toMove = Color.White;


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

    b.toMove = fen.activePlayer;

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

  Bitboard attacks(Color color)()
  {
    // Pawns
    static if (color == Color.White)
    {
      auto westAttacks = boards[color][Piece.Pawn].northwest & enemy!color;
      auto eastAttacks = boards[color][Piece.Pawn].northeast & enemy!color;
    }
    else
    {
      auto westAttacks = boards[color][Piece.Pawn].southwest & enemy!color;
      auto eastAttacks = boards[color][Piece.Pawn].southeast & enemy!color;
    }

    auto pawnAttacks = westAttacks | eastAttacks;

    // Kings
    auto kings = boards[color][Piece.King];
    auto kingAttacks = (kings.north |
                        kings.northeast |
                        kings.east |
                        kings.southeast |
                        kings.south |
                        kings.southwest |
                        kings.west |
                        kings.northwest) & enemy!color;

    // Queens
    auto queens = boards[color][Piece.Queen];
    auto queenAttacks = (marchCollisions(queens, &north) |
                         marchCollisions(queens, &northeast) |
                         marchCollisions(queens, &east) |
                         marchCollisions(queens, &southeast) |
                         marchCollisions(queens, &south) |
                         marchCollisions(queens, &southwest) |
                         marchCollisions(queens, &west) |
                         marchCollisions(queens, &northwest)) & enemy!color;

    // Bishops
    auto bishops = boards[color][Piece.Bishop];
    auto bishopAttacks = (marchCollisions(bishops, &northeast) |
                          marchCollisions(bishops, &southeast) |
                          marchCollisions(bishops, &southwest) |
                          marchCollisions(bishops, &northwest)) & enemy!color;

    // Knights
    auto knights = boards[color][Piece.Knight];
    auto knightAttacks = (knights.northeast.north |
                          knights.northeast.east |
                          knights.southeast.east |
                          knights.southeast.south |
                          knights.southwest.south |
                          knights.southwest.west |
                          knights.northwest.west |
                          knights.northwest.north) & enemy!color;

    // Rooks
    auto rooks = boards[color][Piece.Rook];
    auto rookAttacks = (marchCollisions(rooks, &north) |
                        marchCollisions(rooks, &east) |
                        marchCollisions(rooks, &south) |
                        marchCollisions(rooks, &west)) & enemy!color;

    return (pawnAttacks |
            kingAttacks |
            queenAttacks |
            bishopAttacks |
            knightAttacks |
            rookAttacks);
  }

  bool inCheck(Color c)()
  {
    return (attacks!(not!c) & boards[c][Piece.King]) > 0;
  }

  bool inCheck(Color c)
  {
    if (c == Color.White)
    {
      return inCheck!(Color.White);
    }
    else
    {
      return inCheck!(Color.Black);
    }
  }

  Move[] moves(Color color, Piece piece)
  {
    if (color == Color.White)
    {
      final switch (piece)
      {
      case Piece.King:
        return moves!(Color.White, Piece.King);
      case Piece.Queen:
        return moves!(Color.White, Piece.Queen);
      case Piece.Rook:
        return moves!(Color.White, Piece.Rook);
      case Piece.Bishop:
        return moves!(Color.White, Piece.Bishop);
      case Piece.Knight:
        return moves!(Color.White, Piece.Knight);
      case Piece.Pawn:
        return moves!(Color.White, Piece.Pawn);
      }
    }
    else
    {
      final switch(piece)
      {
      case Piece.King:
        return moves!(Color.Black, Piece.King);
      case Piece.Queen:
        return moves!(Color.Black, Piece.Queen);
      case Piece.Rook:
        return moves!(Color.Black, Piece.Rook);
      case Piece.Bishop:
        return moves!(Color.Black, Piece.Bishop);
      case Piece.Knight:
        return moves!(Color.Black, Piece.Knight);
      case Piece.Pawn:
        return moves!(Color.Black, Piece.Pawn);
      }
    }
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

  void move(Move givenMove)
  {
    Bitboard source = (1L << givenMove.source);
    Bitboard destination = (1L << givenMove.destination);

    // Ensure the piece is where the source says it is.
    if ((boards[toMove][givenMove.piece] & source) == 0L)
    {
      throw new Exception("Invalid move. No piece on: " ~ givenMove.source);
    }

    // Ensure the piece can move to the destination
    // TODO:: Make this faster
    Move[] possibles = moves(toMove, givenMove.piece);

    if (!std.algorithm.canFind(possibles, givenMove))
    {
      throw new Exception("Illegal move!");
    }

    // Conditionally make the move.
    boards[toMove][givenMove.piece] = boards[toMove][givenMove.piece].remove(source);
    boards[toMove][givenMove.piece] = boards[toMove][givenMove.piece] | destination;

    // Check if this leave the active player in check;
    if (inCheck(toMove))
    {
      // Undo the move
      boards[toMove][givenMove.piece] = boards[toMove][givenMove.piece].remove(destination);
      boards[toMove][givenMove.piece] = boards[toMove][givenMove.piece] | source;

      throw new Exception("Move leaves king in check!");
    }
  }
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
