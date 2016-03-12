module dhess.Board;

import dhess.Pieces;
import dhess.Position;
import dhess.Bitboard;
import dhess.Magic;
import dhess.FEN;
import dhess.Move;

import std.conv;
import std.typecons;

struct Castling
{
  bool whiteKingSide = false;
  bool whiteQueenSide = false;
  bool blackKingSide = false;
  bool blackQueenSide = false;

  bool opIndex(Color c, Piece p) const
  {
    if (c == Color.White)
    {
      if (p == Piece.King)
      {
        return whiteKingSide;
      }
      else if (p == Piece.Queen)
      {
        return whiteQueenSide;
      }
      else
      {
        assert(false, "No castling info for piece: " ~ p.to!string);
      }
    }
    else
    {
      if (p == Piece.King)
      {
        return blackKingSide;
      }
      else if (p == Piece.Queen)
      {
        return blackQueenSide;
      }
      else
      {
        assert(false, "No castling info for piece: " ~ p.to!string);
      }
    }
  }

  void opIndexAssign(bool val, Color c, Piece p)
  {
     if (c == Color.White)
    {
      if (p == Piece.King)
      {
        whiteKingSide = val;
      }
      else if (p == Piece.Queen)
      {
        whiteQueenSide = val;
      }
      else
      {
        assert(false, "No castling info for piece: " ~ p.to!string);
      }
    }
    else
    {
      if (p == Piece.King)
      {
        blackKingSide = val;
      }
      else if (p == Piece.Queen)
      {
        blackQueenSide = val;
      }
      else
      {
        assert(false, "No castling info for piece: " ~ p.to!string);
      }
    }
  }

  string serialize() const
  {
    string ret = "";
    if (whiteKingSide)
    {
      ret ~= "K";
    }
    if (whiteQueenSide)
    {
      ret ~= "Q";
    }
    if (blackKingSide)
    {
      ret ~= "k";
    }
    if (blackQueenSide)
    {
      ret ~= "q";
    }
    if (ret == "")
    {
      ret = "-";
    }
    return ret;
  }
}

struct Board
{
  Bitboard[6][2] boards;

  Color toMove = Color.White;
  Castling castling;
  Nullable!Square enPassant = Nullable!Square();
  int drawClock;
  int moveClock;

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
    auto castling = fen.castling;

    b.castling[Color.White, Piece.King] = castling[Color.White][Piece.King];
    b.castling[Color.White, Piece.Queen] = castling[Color.White][Piece.Queen];
    b.castling[Color.Black, Piece.King] = castling[Color.Black][Piece.King];
    b.castling[Color.Black, Piece.Queen] = castling[Color.Black][Piece.Queen];



    b.enPassant = fen.enPassant;
    b.drawClock = fen.drawClock;
    b.moveClock = fen.moveClock;

    return b;
  }

private:
  Bitboard all() const
  {
    return all!(Color.White) | all!(Color.Black);
  }

  Bitboard empty() const
  {
    return ~all;
  }

  Bitboard all(Color c)() const
  {
    return boards[c][Piece.King] |
      boards[c][Piece.Queen] |
      boards[c][Piece.Knight] |
      boards[c][Piece.Rook] |
      boards[c][Piece.Bishop] |
      boards[c][Piece.Pawn];
  }

  Bitboard enemy(Color c)() const
  {
    return all!(not!c);
  }

  Bitboard enemy(Color c) const
  {
    if (c == Color.White)
    {
      return enemy!(Color.White);
    }
    else
    {
      return enemy!(Color.White);
    }
  }

  Bitboard attackedSquares(Color color)() const
  {
    // Pawns
    static if (color == Color.White)
    {
      auto westAttacks = boards[color][Piece.Pawn].northwest;
      auto eastAttacks = boards[color][Piece.Pawn].northeast;
    }
    else
    {
      auto westAttacks = boards[color][Piece.Pawn].southwest;
      auto eastAttacks = boards[color][Piece.Pawn].southeast;
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
                        kings.northwest);

    // Queens
    Bitboard queens = boards[color][Piece.Queen];
    Bitboard queenAttacks = 0UL;
    while (queens > 0)
    {
      auto source = queens.LS1B;

      auto orthMagicIndex = ((all & OrthogonalRays[source]) * OrthogonalMagics[source]) >> (64 - OrthogonalShifts[source]);
      auto diagMagicIndex = ((all & DiagonalRays[source]) * DiagonalMagics[source]) >> (64 - DiagonalShifts[source]);
      auto movesAndAttacks =
        OrthogonalDatabase[source][orthMagicIndex] |
        DiagonalDatabase[source][diagMagicIndex]; // Tadahhhh!!!
      queenAttacks |= movesAndAttacks;

      queens = queens.resetLS1B;
    }


    // Bishops
    Bitboard bishops = boards[color][Piece.Bishop];
    Bitboard bishopAttacks = 0UL;
    while (bishops > 0)
    {
      auto source = bishops.LS1B;
      auto diagMagicIndex = ((all & DiagonalRays[source]) * DiagonalMagics[source]) >> (64 - DiagonalShifts[source]);
      auto movesAndAttacks = DiagonalDatabase[source][diagMagicIndex]; // Tadahhhh!!!
      bishopAttacks |= movesAndAttacks;

      bishops = bishops.resetLS1B;
    }

    // Knights
    auto knights = boards[color][Piece.Knight];
    auto knightAttacks = (knights.northeast.north |
                          knights.northeast.east |
                          knights.southeast.east |
                          knights.southeast.south |
                          knights.southwest.south |
                          knights.southwest.west |
                          knights.northwest.west |
                          knights.northwest.north);

    // Rooks
    Bitboard rooks = boards[color][Piece.Rook];
    auto rookAttacks = 0UL;
    while (rooks > 0)
    {
      auto sq = rooks.LS1B;

      auto magicIndex = ((all & OrthogonalRays[sq]) * OrthogonalMagics[sq]) >> (64 - OrthogonalShifts[sq]);
      auto movesAndAttacks = OrthogonalDatabase[sq][magicIndex]; // Tadahhhh!!!
      rookAttacks |= movesAndAttacks;

      rooks = rooks.resetLS1B;
    }

    return (pawnAttacks |
            kingAttacks |
            queenAttacks |
            bishopAttacks |
            knightAttacks |
            rookAttacks);
  }

  Bitboard attackedPieces(Color color)() const
  {
    return attackedSquares!(color) & enemy!color;
  }

  Bitboard attackedPieces(Color c) const
  {
    if (c == Color.White)
    {
      return attackedPieces(Color.White);
    }
    else
    {
      return attackedPieces(Color.Black);
    }
  }

  bool inCheck(Color c)() const
  {
    return (attackedPieces!(not!c) & boards[c][Piece.King]) > 0;
  }

  bool inCheck(Color c) const
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

  Move[] moves(Color color, Piece piece) const
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
      case Piece.None:
        assert(false, "Can't get moves for the None piece");
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
      case Piece.None:
        assert(false, "Can't get moves for the None piece");
      }
    }
  }

  Piece on(Square sq) const
  {
    Bitboard square = (1L << sq);
    if ((boards[Color.White][Piece.King] | boards[Color.Black][Piece.King]) & square)
    {
      return Piece.King;
    }
    else if ((boards[Color.White][Piece.Queen] | boards[Color.Black][Piece.Queen]) & square)
    {
      return Piece.Queen;
    }
    else if ((boards[Color.White][Piece.Rook] | boards[Color.Black][Piece.Rook]) & square)
    {
      return Piece.Rook;
    }
    else if ((boards[Color.White][Piece.Bishop] | boards[Color.Black][Piece.Bishop]) & square)
    {
      return Piece.Bishop;
    }
    else if ((boards[Color.White][Piece.Knight] | boards[Color.Black][Piece.Knight]) & square)
    {
      return Piece.Knight;
    }
    else if ((boards[Color.White][Piece.Pawn] | boards[Color.Black][Piece.Pawn]) & square)
    {
      return Piece.Pawn;
    }
    return Piece.None;
  }

public:

  // Pawns -------------------------------------------------------------------------------------------
  Move[] moves(Color color, Piece piece)() const
    if (piece == Piece.Pawn)
  {
    Move[] buildMove(Color color)(Square source,
                                 Square dest,
                                 Piece capturePiece = Piece.None,
                                 Square captureSquare = Square.init)
    {
      // If it's on the enemy home rank, fill in promotions.
      auto destBoard = (1L << dest);
      static if (color == Color.White)
      {
        if ((destBoard & RANK_8) > 0)
        {
          return [
            Move(Piece.Pawn, source, dest, capturePiece, captureSquare, Piece.Queen),
            Move(Piece.Pawn, source, dest, capturePiece, captureSquare, Piece.Rook),
            Move(Piece.Pawn, source, dest, capturePiece, captureSquare, Piece.Bishop),
            Move(Piece.Pawn, source, dest, capturePiece, captureSquare, Piece.Knight)
            ];
        }
      }
      else
      {
        if ((destBoard & RANK_1) > 0)
        {
          return [
            Move(Piece.Pawn, source, dest, capturePiece, captureSquare, Piece.Queen),
            Move(Piece.Pawn, source, dest, capturePiece, captureSquare, Piece.Rook),
            Move(Piece.Pawn, source, dest, capturePiece, captureSquare, Piece.Bishop),
            Move(Piece.Pawn, source, dest, capturePiece, captureSquare, Piece.Knight)
            ];
        }
      }

      // Otherwise no promotions are necessary
      return [Move(Piece.Pawn, source, dest, capturePiece, captureSquare)];
    }

    enum pushDirection = (color == Color.White) ? 8 : -8;
    enum westAttackDirection = (color == Color.White) ? 9 : -7;
    enum eastAttackDirection = (color == Color.White) ? 7 : -9;

    Move[] ret = [];

    // Single pushes
    static if (color == Color.White)
    {
      auto singles = (boards[color][piece].north & empty);
    }
    else
    {
      auto singles = (boards[color][piece].south & empty);
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
      auto source = (sq - pushDirection).to!Square;
      ret ~= buildMove!(color)(source, sq);
      singles = singles.resetLS1B;
    }

    while (doubles > 0)
    {
      auto sq = doubles.LS1B;
      auto source = (sq - 2*pushDirection).to!Square;
      ret ~= buildMove!(color)(source, sq);
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
      auto source = (sq - westAttackDirection).to!Square;
      ret ~= buildMove!(color)(source, sq, on(sq), sq);
      westAttacks = westAttacks.resetLS1B;
    }

    // east attacks
    while (eastAttacks > 0)
    {
      auto sq = eastAttacks.LS1B;
      auto source = (sq - eastAttackDirection).to!Square;
      ret ~= buildMove!(color)(source, sq, on(sq), sq);
      eastAttacks = eastAttacks.resetLS1B;
    }

    // En Passant
    if (!enPassant.isNull)
    {
      auto enPassantSq = (1L << enPassant.get);
      static if (color == Color.White)
      {
        auto westEnPassant = boards[color][piece].northwest & enPassantSq;
        auto eastEnPassant = boards[color][piece].northeast & enPassantSq;
      }
      else
      {
        auto westEnPassant = boards[color][piece].southwest & enPassantSq;
        auto eastEnPassant = boards[color][piece].southeast & enPassantSq;
      }

      while (westEnPassant > 0)
      {
        auto sq = westEnPassant.LS1B;
        auto source = (sq - westAttackDirection).to!Square;
        ret ~= buildMove!(color)(source, sq, Piece.Pawn, (sq - pushDirection).to!Square);
        westEnPassant = westEnPassant.resetLS1B;
      }

      while (eastEnPassant > 0)
      {
        auto sq = eastEnPassant.LS1B;
        auto source = (sq - eastAttackDirection).to!Square;
        ret ~= buildMove!(color)(source, sq, Piece.Pawn, (sq- pushDirection).to!Square);
        eastEnPassant = eastEnPassant.resetLS1B;
      }
    }

    return ret;
  }

  // Knights ---------------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)() const
    if (p == Piece.Knight)
  {
    Move[] ret = [];

    Bitboard knights = boards[c][p];
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
        auto piece = on(dest);
        auto captureSquare = (piece == Piece.None) ? Square.init: dest;
        ret ~= Move(Piece.Knight, source, dest, piece, captureSquare);
        knightMoves = knightMoves.resetLS1B;
      }

      knights = knights.resetLS1B;
    }

    return ret;
  }

  // King ---------------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)() const
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
      auto dest = possible.LS1B;
      auto piece = on(dest);
      auto captureSquare = (piece == Piece.None) ? Square.init: dest;
      ret ~= Move(Piece.King, source, dest, piece, captureSquare);
      possible = possible.resetLS1B;
    }

    ret ~= castlingMoves(c);
    return ret;
  }

  private Move[] castlingMoves(Color c)() const
  {
    // Cannot castle if King is in check.
    if (inCheck(toMove))
    {
      return [];
    }

    static if (c == Color.White)
    {
      auto kingSideSquares = F_1 | G_1;
      auto queenSideNoCheck = C_1 | D_1;
      auto queenSideEmpty = B_1 | C_1 | D_1;
      auto kingSquare = Square.E1;
      auto kingSideSquare = Square.G1;
      auto kingSideRook = H_1;
      auto queenSideSquare = Square.C1;
      auto queenSideRook = A_1;
    }
    else
    {
      auto kingSideSquares = F_8 | G_8;
      auto queenSideNoCheck = C_8 | D_8;
      auto queenSideEmpty = B_8 | C_8 | D_8;
      auto kingSquare = Square.E8;
      auto kingSideSquare = Square.G8;
      auto kingSideRook = H_8;
      auto queenSideSquare = Square.C8;
      auto queenSideRook = A_8;
    }

    Move[] ret = [];
    if (castling[c, Piece.King])
    {
      // There is space to castle:
      bool squaresEmpty = (all & kingSideSquares) == 0;
      // Not castling through check
      bool squaresInCheck = (attackedSquares!(not!c) & kingSideSquares) > 0;
      bool rookIsThere = (boards[c][Piece.Rook] & kingSideRook) > 0;
      if (squaresEmpty && !squaresInCheck && rookIsThere)
      {
        ret ~= Move(Piece.King, kingSquare, kingSideSquare);
      }
    }
    if (castling[c, Piece.Queen])
    {
       // There is space to castle:
      bool squaresEmpty = (all & queenSideEmpty) == 0;
      // Not castling through check
      bool squaresInCheck = (attackedSquares!(not!c) & queenSideNoCheck) > 0;
      bool rookIsThere = (boards[c][Piece.Rook] & queenSideRook) > 0;
      if (squaresEmpty && !squaresInCheck && rookIsThere)
      {
        ret ~= Move(Piece.King, kingSquare, queenSideSquare);
      }
    }
    return ret;
  }

  private Move[] castlingMoves(Color c) const
  {
    if (c == Color.White)
    {
      return castlingMoves!(Color.White);
    }
    else
    {
      return castlingMoves!(Color.Black);
    }
  }


  // Rooks ---------------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)() const
    if (p == Piece.Rook)
  {
    Move[] ret = [];

    Bitboard rooks = boards[c][p];

    while (rooks > 0)
    {
      auto sq = rooks.LS1B;
      Bitboard rook = (1L << sq);

      auto magicIndex = ((all & OrthogonalRays[sq]) * OrthogonalMagics[sq]) >> (64 - OrthogonalShifts[sq]);
      auto movesAndAttacks = OrthogonalDatabase[sq][magicIndex]; // Tadahhhh!!!
      auto moves = movesAndAttacks & empty;
      auto attacks = movesAndAttacks & enemy!c;

      while (moves > 0)
      {
        auto dest = moves.LS1B;
        ret ~= Move(Piece.Rook, sq, dest);
        moves = moves.resetLS1B;
      }

      while (attacks > 0)
      {
        auto dest = attacks.LS1B;
        ret ~= Move(Piece.Rook, sq, dest, on(dest), dest);
        attacks = attacks.resetLS1B;
      }

      rooks = rooks.resetLS1B;
    }

    return ret;
  }

  // Bishops ----------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)() const
    if (p == Piece.Bishop)
  {
    Move[] ret = [];

    Bitboard bishops = boards[c][p];

    while (bishops > 0)
    {
      auto source = bishops.LS1B;
      auto bishop = (1L << source);

      auto magicIndex = ((all & DiagonalRays[source]) * DiagonalMagics[source]) >> (64 - DiagonalShifts[source]);
      auto movesAndAttacks = DiagonalDatabase[source][magicIndex]; // Tadahhhh!!!
      auto moves = movesAndAttacks & empty;
      auto attacks = movesAndAttacks & enemy!c;

      while (moves > 0)
      {
        auto dest = moves.LS1B;
        ret ~= Move(Piece.Bishop, source, dest);
        moves = moves.resetLS1B;
      }

      while (attacks > 0)
      {
        auto dest = attacks.LS1B;
        ret ~= Move(Piece.Bishop, source, dest, on(dest), dest);
        attacks = attacks.resetLS1B;
      }

      bishops = bishops.resetLS1B;
    }

    return ret;
  }

  // Queens --------------------------------------------------------------------------------
  Move[] moves(Color c, Piece p)() const
    if (p == Piece.Queen)
  {
    Move[] ret = [];

    Bitboard queens = boards[c][p];

    while (queens > 0)
    {
      auto source = queens.LS1B;
      auto queen = (1L << source);

      auto orthMagicIndex = ((all & OrthogonalRays[source]) * OrthogonalMagics[source]) >> (64 - OrthogonalShifts[source]);
      auto diagMagicIndex = ((all & DiagonalRays[source]) * DiagonalMagics[source]) >> (64 - DiagonalShifts[source]);
      auto movesAndAttacks =
        OrthogonalDatabase[source][orthMagicIndex] |
        DiagonalDatabase[source][diagMagicIndex]; // Tadahhhh!!!

      auto moves = movesAndAttacks & empty;
      auto attacks = movesAndAttacks & enemy!c;

      while (moves > 0)
      {
        auto dest = moves.LS1B;
        ret ~= Move(Piece.Queen, source, dest);
        moves = moves.resetLS1B;
      }

      while (attacks > 0)
      {
        auto dest = attacks.LS1B;
        ret ~= Move(Piece.Queen, source, dest, on(dest), dest);
        attacks = attacks.resetLS1B;
      }

      queens = queens.resetLS1B;
    }

    return ret;
  }

  // All --------------------------------------------------------------------------------------
  Move[] moves(Color c)() const
  {
    return moves!(c, Piece.Pawn) ~
      moves!(c, Piece.Knight) ~
      moves!(c, Piece.King) ~
      moves!(c, Piece.Bishop) ~
      moves!(c, Piece.Rook) ~
      moves!(c, Piece.Queen);
  }

  Move[] moves() const
  {
    if (toMove == Color.White)
    {
      return moves!(Color.White);
    }
    else
    {
      return moves!(Color.Black);
    }
  }

  bool legal(Move givenMove)
  {
    if (toMove == Color.White)
    {
      return legal!(Color.White)(givenMove);
    }
    else
    {
      return legal!(Color.Black)(givenMove);
    }
  }

  bool legal(Color c)(Move givenMove)
  {
     Bitboard source = (1L << givenMove.source);
     Bitboard destination = (1L << givenMove.destination);

     version(unittest)
     {
       // Ensure the piece is where the source says it is.
       if ((boards[c][givenMove.piece] & source) == 0L)
       {
         return false;
       }

       // Ensure the piece can move to the destination
       Move[] possibles = moves(c, givenMove.piece);
       if (!std.algorithm.canFind(possibles, givenMove))
       {
         return false;
       }
     }

     // Assert this is outwardly const;
     version(unittest)
     {
       Board cp = this;
     }

     // Conditionally make the move.
     makeMove!c(givenMove);

     // Check if this leave the active player in check;
     auto legal = !inCheck!c;
     // Undo the move.
     unmakeMove!c(givenMove);

     version(unittest)
     {
       import std.conv;
       assert(this.boards == cp.boards, "Make/Unmake not const for move: " ~ givenMove.to!string);
     }

     return legal;
  }

  void move(Move givenMove)
  {
    if (toMove == Color.White)
    {
      move!(Color.White)(givenMove);
    }
    else
    {
      move!(Color.Black)(givenMove);
    }
  }

  // CAN MAKE ILLEGAL MOVES!!!
  private void makeMove(Color c)(Move givenMove)
  {
    Bitboard source = (1L << givenMove.source);
    Bitboard destination = (1L << givenMove.destination);
    Bitboard capture = (1L << givenMove.captureSquare);

    // Make the move
    boards[c][givenMove.piece] = boards[c][givenMove.piece].remove(source);
    boards[c][givenMove.piece] = boards[c][givenMove.piece] | destination;

    // Remove the captured piece
    if(givenMove.capture != Piece.None)
    {
      version(unittest)
      {
        assert((boards[not!c][givenMove.capture] & capture) > 0, "Attempted to capture a non-existent piece");
      }
      boards[not!c][givenMove.capture] = boards[not!c][givenMove.capture].remove(capture);
    }
  }

  private void unmakeMove(Color c)(Move givenMove)
  {
    Bitboard source = (1L << givenMove.source);
    Bitboard destination = (1L << givenMove.destination);
    Bitboard capture = (1L << givenMove.captureSquare);

    // UnMake the move
    boards[c][givenMove.piece] = boards[c][givenMove.piece].remove(destination);
    boards[c][givenMove.piece] = boards[c][givenMove.piece] | source;

    // Remove the captured piece
    if(givenMove.capture != Piece.None)
    {
      boards[not!c][givenMove.capture] = boards[not!c][givenMove.capture] | capture;
    }
  }

  private void move(Color c)(Move givenMove)
  {
    if (!legal(givenMove))
    {
      throw new Exception("Illegal move!");
    }

    Bitboard source = (1L << givenMove.source);
    Bitboard destination = (1L << givenMove.destination);

    // Move is legal, so go ahead and make it
    makeMove!c(givenMove);
    static if (c == Color.Black)
    {
      this.moveClock++;
    }
    this.drawClock++;

    // Check for a new en passant target
    this.enPassant = Nullable!Square();
    import std.math;
    if (givenMove.piece == Piece.Pawn && abs(givenMove.destination - givenMove.source) == 16)
    {
      static if (c == Color.White)
      {
        this.enPassant = Nullable!Square((givenMove.source + 8).to!Square);
      }
      else
      {
        this.enPassant = Nullable!Square((givenMove.source - 8).to!Square);
      }
    }

    // Update castling eligibility
    if (givenMove.piece == Piece.King)
    {
      castling[c, Piece.King] = false;
      castling[c, Piece.Queen] = false;
    }
    if (givenMove.piece == Piece.Rook)
    {
      static if (c == Color.White)
      {
        if (givenMove.source == Square.H1)
        {
          castling[c, Piece.King] = false;
        }
        else if (givenMove.source == Square.A1)
        {
          castling[c, Piece.Queen] = false;
        }
      }
      else
      {
        if (givenMove.source == Square.H8)
        {
          castling[c, Piece.King] = false;
        }
        else if (givenMove.source == Square.A8)
        {
          castling[c, Piece.Queen] = false;
        }
      }
    }
    // If a rook has been captured, the enemy can't castle with it anymore
    static if (c == Color.White)
    {
      if (givenMove.capture == Piece.Rook)
      {
        if (givenMove.captureSquare == Square.H8)
        {
          castling[not!c, Piece.King] = false;
        }
        else if (givenMove.captureSquare == Square.A8)
        {
          castling[not!c, Piece.Queen] = false;
        }
      }
    }
    else
    {
      if (givenMove.capture == Piece.Rook)
      {
        if (givenMove.captureSquare == Square.H1)
        {
          castling[not!c, Piece.King] = false;
        }
        else if (givenMove.captureSquare == Square.A1)
        {
          castling[not!c, Piece.Queen] = false;
        }
      }
    }

    // If this is a castle move, also move the rook.
    if (givenMove.isCastling)
    {
      switch (givenMove.destination)
      {
      // White Kingside
      case Square.G1:
        boards[Color.White][Piece.Rook] = boards[Color.White][Piece.Rook].remove(H_1);
        boards[Color.White][Piece.Rook] = boards[Color.White][Piece.Rook] | F_1;
        break;
      // White Queenside
      case Square.C1:
        boards[Color.White][Piece.Rook] = boards[Color.White][Piece.Rook].remove(A_1);
        boards[Color.White][Piece.Rook] = boards[Color.White][Piece.Rook] | D_1;
        break;
      // Black Kingside
      case Square.G8:
        boards[Color.Black][Piece.Rook] = boards[Color.Black][Piece.Rook].remove(H_8);
        boards[Color.Black][Piece.Rook] = boards[Color.Black][Piece.Rook] | F_8;
        break;
      // White Queenside
      case Square.C8:
        boards[Color.Black][Piece.Rook] = boards[Color.Black][Piece.Rook].remove(A_8);
        boards[Color.Black][Piece.Rook] = boards[Color.Black][Piece.Rook] | D_8;
        break;
      default:
        throw new Exception("Invalid isCastling: Returned true for destination: " ~ givenMove.destination);
      }
      castling[c, Piece.King] = false;
      castling[c, Piece.Queen] = false;
    }

    // If this is a capture, remove the captured piece.
    if ((destination & enemy!c) > 0)
    {
      // Update the draw clock
      this.drawClock = 0;
      import std.traits;
      foreach(piece; [EnumMembers!Piece])
      {
        auto board = boards[not!c][piece];
        if ((board & destination) > 0)
        {
          boards[not!c][piece] = board.remove(destination);
        }
      }
    }

    // If this is a pawn move, reset the draw clock.
    if (givenMove.piece == Piece.Pawn)
    {
      this.drawClock = 0;
    }

    // If this is a promotion, remove the mistakenly moved pawn, and replace it with the promotion.
    if (givenMove.promotion != Piece.None)
    {
      assert(givenMove.piece == Piece.Pawn);
      boards[c][Piece.Pawn] = boards[c][Piece.Pawn].remove(destination);
      boards[c][givenMove.promotion] = boards[c][givenMove.promotion] | destination; 
    }

    this.toMove = not!c;
  }

  string serialize() const
  {
    auto board = "";
    for (int i = 63; i >= 0; --i)
    {
      Square sq = i.to!Square;
      board ~= serializeSquare(sq);
    }
    board = board[0..8].collapse ~ "/" ~
            board[8..16].collapse ~ "/" ~
            board[16..24].collapse ~ "/" ~
            board[24..32].collapse ~ "/" ~
            board[32..40].collapse ~ "/" ~
            board[40..48].collapse ~ "/" ~
            board[48..56].collapse ~ "/" ~
            board[56..64].collapse;

    auto activePlayer = (toMove == Color.White)? "w": "b";

    auto castles = castling.serialize;

    import std.string;
    auto enPassant = (enPassant.isNull) ? "-" : enPassant.get().to!string.toLower;
    auto draw = drawClock.to!string;
    auto move = moveClock.to!string;

    return [board, activePlayer, castles, enPassant, draw, move].join(' ');
  }

  // Returns space for empty square
  char serializeSquare(Square square) const
  {
    Bitboard sq = (1L << square);
    if (boards[Color.White][Piece.King] & sq)
    {
      return 'K';
    }
    else if (boards[Color.Black][Piece.King] & sq)
    {
      return 'k';
    }
    else if (boards[Color.White][Piece.Queen] & sq)
    {
      return 'Q';
    }
    else if (boards[Color.Black][Piece.Queen] & sq)
    {
      return 'q';
    }
    else if (boards[Color.White][Piece.Rook] & sq)
    {
      return 'R';
    }
    else if (boards[Color.Black][Piece.Rook] & sq)
    {
      return 'r';
    }
    else if (boards[Color.White][Piece.Bishop] & sq)
    {
      return 'B';
    }
    else if (boards[Color.Black][Piece.Bishop] & sq)
    {
      return 'b';
    }
    else if (boards[Color.White][Piece.Knight] & sq)
    {
      return 'N';
    }
    else if (boards[Color.Black][Piece.Knight] & sq)
    {
      return 'n';
    }
    else if (boards[Color.White][Piece.Knight] & sq)
    {
      return 'N';
    }
    else if (boards[Color.Black][Piece.Knight] & sq)
    {
      return 'n';
    }
    else if (boards[Color.White][Piece.Pawn] & sq)
    {
      return 'P';
    }
    else if (boards[Color.Black][Piece.Pawn] & sq)
    {
      return 'p';
    }
    return ' ';
  }
}


string collapse(string input) 
{
  import std.string;
  return input
    .replace("        ", "8")
    .replace("       ", "7")
    .replace("      ", "6")
    .replace("     ", "5")
    .replace("    ", "4")
    .replace("   ", "3")
    .replace("  ", "2")
    .replace(" ", "1");
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

// Copy construct
unittest
{
  Board a = Board();
  Board b = a;
  a.move(Move(Piece.Pawn, Square.E2, Square.E4));

  assert( a != b);
}

// makeMove
unittest
{
  auto fen = "8/2p5/3p4/KP5r/1R3p1k/6P1/4P3/8 b - - 0 1";
  auto board = Board(fen);
  auto illegal = Move(Piece.Rook, Square.H5, Square.G5);
  assert(!board.legal(illegal));
  board.makeMove!(Color.Black)(illegal);
  assert(board.inCheck!(Color.Black));
  auto expected = "8/2p5/3p4/KP4r1/1R3p1k/6P1/4P3/8 b - - 0 1";
  assert(board.serialize == expected);
}

// makeMove // unmakeMove are effectively const
unittest
{

  auto fen = "8/2p5/3p4/KP5r/1R3p1k/6P1/4P3/8 b - - 0 1";
  auto board = Board(fen);
  auto move = Move(Piece.Pawn, Square.F4, Square.G3, Piece.Pawn, Square.G3);
  board.makeMove!(Color.Black)(move);
  board.unmakeMove!(Color.Black)(move);
  auto fresh = Board(fen);
  assert(board.boards == fresh.boards);
}

