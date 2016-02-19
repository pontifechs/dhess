module chess.Board;

import chess.Pieces;
import chess.Position;
import chess.Bitboard;
import chess.FEN;

struct Board
{
  Bitboard[2] kings;
  Bitboard[2] queens;
  Bitboard[2] bishops;
  Bitboard[2] knights;
  Bitboard[2] rooks;
  Bitboard[2] pawns;


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
        auto color = piece.color;
        final switch (piece.piece)
        {
        case Piece.King:
          b.kings[color]|= pos;
          break;
        case Piece.Queen:
          b.queens[color] |= pos;
          break;
        case Piece.Bishop:
          b.bishops[color] |= pos;
          break;
        case Piece.Knight:
          b.knights[color] |= pos;
          break;
        case Piece.Rook:
          b.rooks[color] |= pos;
          break;
        case Piece.Pawn:
          b.pawns[color] |= pos;
          break;
        }
      }
    }
    return b;
  }

  // Utilities
  // Pawns ----------------------------------------------------------------------------------
  Bitboard all(Color color)()
  {
    return kings[color] | queens[color] | bishops[color] | knights[color] | rooks[color] | pawns[color];
  }

  Bitboard all()
  {
    return all!(Color.Black) | all!(Color.White);
  }

  Bitboard enemy(Color color)()
  {
    return all!(not!color);
  }

  // Move generation:
  private Bitboard pawnPush(Color c)()
    if (c == Color.White)
  {
    return pawns[c].north.remove(all);
  }

  private Bitboard pawnPush(Color c)()
    if (c == Color.Black)
  {
    return pawns[c].south.remove(all);
  }

  private Bitboard pawnDoublePush(Color c)()
    if (c == Color.White)
  {
    return pawnPush!(c).north.remove(all);
  }

  private Bitboard pawnDoublePush(Color c)()
    if (c == Color.Black)
  {
    return pawnPush!(c).south.remove(all);
  }

  Bitboard pawnMoves(Color color)()
  {
    return pawnPush!color | pawnPush!color;
  }

  Bitboard pawnAttacks(Color color)()
  {
    auto westAttacks = pawns[color].northwest & enemy!color;
    auto eastAttacks = pawns[color].northeast & enemy!color;
    return westAttacks | eastAttacks;
  }

  // Knights -----------------------------------------------------------------------------
  private Bitboard knightPossibleMoves(Color c)()
  {
    auto eastNorth = knights[c].northeast.north;
    auto eastNorthEast = knights[c].northeast.east;
    auto eastSouthEast = knights[c].southeast.east;
    auto eastSouth = knights[c].southeast.south;
    auto westNorth = knights[c].northwest.north;
    auto westNorthWest = knights[c].northwest.west;
    auto westSouthWest = knights[c].southwest.west;
    auto westSouth = knights[c].southwest.south;

    auto allPossible = eastNorth | eastNorthEast | eastSouthEast | eastSouth;
    allPossible |= westNorth | westNorthWest | westSouthWest | westSouth;
    return allPossible;
  }

  Bitboard knightMoves(Color c)()
  {
    return knightPossibleMoves!(c).remove(all);
  }

  Bitboard knightAttacks(Color c)()
  {
    return knightPossibleMoves!c & enemy!c;
  }

  // Kings --------------------------------------------------------------
  private Bitboard kingPossibleMoves(Color c)()
  {
    auto ret = 0L;
    ret |= kings[c].north;
    ret |= kings[c].northeast;
    ret |= kings[c].east;
    ret |= kings[c].southeast;
    ret |= kings[c].south;
    ret |= kings[c].southwest;
    ret |= kings[c].west;
    ret |= kings[c].northwest;
    return ret;
  }

  Bitboard kingMoves(Color c)()
  {
    return kingPossibleMoves!(c).remove(all);
  }

  Bitboard kingAttacks(Color c)()
  {
    return kingPossibleMoves!c & enemy!c;
  }

  // Sliding -------------------------------------------------------------------
  alias Move = Bitboard function(Bitboard);
  private Bitboard marchMoves(Bitboard board, Move move)
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

  private Bitboard marchCollisions(Bitboard board, Move move)
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

  // Rooks ----------------------------------------------------------------
  Bitboard rookMoves(Color c)()
  {
    return marchMoves(rooks[c], &north) |
      marchMoves(rooks[c], &east) |
      marchMoves(rooks[c], &south) |
      marchMoves(rooks[c], &west);
  }

  Bitboard rookAttacks(Color c)()
  {
    auto collisions = marchCollisions(rooks[c], &north) |
      marchCollisions(rooks[c], &east) |
      marchCollisions(rooks[c], &south) |
      marchCollisions(rooks[c], &west);
    return collisions & enemy!c;
  }

  // Bishops --------------------------------------------------------
  Bitboard bishopMoves(Color c)()
  {
    return marchMoves(bishops[c], &northeast) |
      marchMoves(bishops[c], &southeast) |
      marchMoves(bishops[c], &southwest) |
      marchMoves(bishops[c], &northwest);
  }

  Bitboard bishopAttacks(Color c)()
  {
    auto collisions = marchCollisions(bishops[c], &northeast) |
      marchCollisions(bishops[c], &southeast) |
      marchCollisions(bishops[c], &southwest) |
      marchCollisions(bishops[c], &northwest);
    return collisions & enemy!c;
  }

  // Queens ---------------------------------------------------------------
  Bitboard queenMoves(Color c)()
  {
    return marchMoves(queens[c], &north) |
      marchMoves(queens[c], &northeast) |
      marchMoves(queens[c], &east) |
      marchMoves(queens[c], &southeast) |
      marchMoves(queens[c], &south) |
      marchMoves(queens[c], &southwest) |
      marchMoves(queens[c], &west) |
      marchMoves(queens[c], &northwest);
  }

  Bitboard queenAttacks(Color c)()
  {
    auto collisions = marchCollisions(queens[c], &north) |
      marchCollisions(queens[c], &northeast) |
      marchCollisions(queens[c], &east) |
      marchCollisions(queens[c], &southeast) |
      marchCollisions(queens[c], &south) |
      marchCollisions(queens[c], &southwest) |
      marchCollisions(queens[c], &west) |
      marchCollisions(queens[c], &northwest);
    return collisions & enemy!c;
  }
}

// Build from FEN
unittest
{
  Board board = Board();

  assert(board.pawns[Color.White] == RANK_2);
  assert(board.pawns[Color.Black] == RANK_7);
  assert(board.kings[Color.White] == E_1);
  assert(board.kings[Color.Black] == E_8);
  assert(board.queens[Color.White] == D_1);
  assert(board.queens[Color.Black] == D_8);
  assert(board.bishops[Color.White] == (C_1 | F_1));
  assert(board.bishops[Color.Black] == (C_8 | F_8));
  assert(board.knights[Color.White] == (B_1 | G_1));
  assert(board.knights[Color.Black] == (B_8 | G_8));
  assert(board.rooks[Color.White] == (A_1 | H_1));
  assert(board.rooks[Color.Black] == (A_8 | H_8));
}

//  all black/all white
unittest
{
  Board board = Board();

  assert(board.all!(Color.Black) == (RANK_7 | RANK_8));
  assert(board.all!(Color.White) == (RANK_1 | RANK_2));
}

// whitePawnPush
unittest
{
  Board neutral = Board();
  assert(neutral.pawnPush!(Color.White) == RANK_3);

  FEN singleBlockerFEN = "rnbqkbnr/pppppppp/8/8/8/3R4/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  Board singleBlocker = Board(singleBlockerFEN);
  assert(singleBlocker.pawnPush!(Color.White) == (A_3 | B_3 | C_3 | E_3 | F_3 | G_3 | H_3));

  FEN allBlockedFEN = "PPPPPPPP/8/8/8/8/8/8/8 w KQkq - 0 1";
  Board allBlocked = Board(allBlockedFEN);
  assert(allBlocked.pawnPush!(Color.White) == 0L);
}

// whiteDoublePush
unittest
{
  Board neutral = Board();
  assert(neutral.pawnDoublePush!(Color.White) == RANK_4);

  FEN singleBlockerFEN = "rnbqkbnr/pppppppp/8/8/8/3R4/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  Board singleBlocker = Board(singleBlockerFEN);
  assert(singleBlocker.pawnDoublePush!(Color.White) == (A_4 | B_4 | C_4 | E_4 | F_4 | G_4 | H_4));

  FEN twoRankBlockerFEN = "rnbqkbnr/pppppppp/8/8/2r5/3R4/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  Board twoRankBlocker = Board(twoRankBlockerFEN);
  assert(twoRankBlocker.pawnDoublePush!(Color.White) == (A_4 | B_4 | E_4 | F_4 | G_4 | H_4));

  FEN allBlockedFEN = "8/PPPPPPPP/8/8/8/8/8/8 w KQkq - 0 1";
  Board allBlocked = Board(allBlockedFEN);
  assert(allBlocked.pawnDoublePush!(Color.White) == 0L);
}

// whitePawnAttacks
unittest
{

  FEN singleFEN = "8/8/8/8/8/p7/1P6/8 w KQkq - 0 1";
  Board single = Board(singleFEN);
  assert(single.pawnAttacks!(Color.White) == A_3);

  FEN allFEN = "8/8/8/8/8/8/pppppppp/PPPPPPPP w KQkq - 0 1";
  Board all = Board(allFEN);
  assert(all.pawnAttacks!(Color.White) == RANK_2);

  FEN allButOneFEN = "8/8/8/8/8/8/pppp1ppp/PPPPPPPP w KQkq - 0 1";
  Board allButOne = Board(allButOneFEN);
  assert(allButOne.pawnAttacks!(Color.White) == RANK_2.remove(E_2));
}

// whiteKnightMoves
unittest
{
  FEN middleFEN = "8/8/8/8/3N4/8/8/8 w KQkq - 0 1";
  // Knight on D4
  Board middle = Board(middleFEN);
  auto middleMoves = E_6 | F_5 | F_3 | E_2 | C_2 | B_3 | B_5 | C_6;
  assert(middle.knightMoves!(Color.White)== middleMoves);

  FEN middleBlockedFEN = "8/8/2R1R3/1R3R2/3N4/1R3R2/2R1R3/8 w KQkq - 0 1";
  Board middleBlocked = Board(middleBlockedFEN);
  assert(middleBlocked.knightMoves!(Color.White) == 0L);

  FEN cornerFEN = "8/8/8/8/8/8/8/N7 w KQkq - 0 1";
  Board corner = Board(cornerFEN);
  assert(corner.knightMoves!(Color.White)== (B_3 | C_2));
}

// whiteKnightAttacks
unittest
{
  FEN middleFEN = "8/8/8/8/3N4/8/8/8 w KQkq - 0 1";
  // Knight on D4
  Board middle = Board(middleFEN);
  assert(middle.knightAttacks!(Color.White) == 0L);

  FEN middleBlockedFEN = "8/8/2r1r3/1r3r2/3N4/1r3r2/2r1r3/8 w KQkq - 0 1";
  Board middleBlocked = Board(middleBlockedFEN);
  auto middleAttacks = E_6 | F_5 | F_3 | E_2 | C_2 | B_3 | B_5 | C_6;
  assert(middleBlocked.knightAttacks!(Color.White) == middleAttacks);

  FEN selfAttackFEN = "8/8/2R1R3/1R3R2/3N4/1R3R2/2R1R3/8 w KQkq - 0 1";
  Board selfAttack = Board(selfAttackFEN);
  assert(selfAttack.knightAttacks!(Color.White) == 0L);
}

// whiteKingMoves / attacks
unittest
{
  FEN middleFEN = "8/8/8/8/3K4/8/8/8 w KQkq - 0 1";
  // King on D4
  Board middle = Board(middleFEN);
  auto middleMoves = C_5 | D_5 | E_5 | C_4 | E_4 | C_3 | D_3 | E_3;
  assert(middle.kingMoves!(Color.White) == middleMoves);
  assert(middle.kingAttacks!(Color.White) == 0L);

  FEN attackFEN = "8/8/8/2p1p3/3K4/2p1p3/8/8 w KQkq - 0 1";
  Board attack = Board(attackFEN);
  auto attackMoves = C_5 | E_5 | C_3 | E_3;
  assert(attack.kingAttacks!(Color.White) == attackMoves);
}

// whiteRookMoves
unittest
{
  FEN middleFEN = "8/pppppppp/8/8/3R4/8/8/8 w KQkq - 0 1";
  Board middle = Board(middleFEN);
  auto moves = A_4 | B_4 | C_4 | E_4 | F_4 | G_4 | G_4 | H_4 | D_1 | D_2 | D_3 | D_5 | D_6;
  assert(middle.rookMoves!(Color.White) == moves);

  FEN surroundedFEN = "8/8/8/3p4/2pRp3/3p4/8/8 w KQkq - 0 1";
  Board surrounded = Board(surroundedFEN);
  assert(surrounded.rookMoves!(Color.White) == 0L);
}

// whiteRookAttacks
unittest
{
  FEN middleFEN = "8/pppppppp/8/8/3R4/8/8/8 w KQkq - 0 1";
  Board middle = Board(middleFEN);
  assert(middle.rookAttacks!(Color.White) == D_7);

  FEN surroundedFEN = "8/8/8/3p4/2pRp3/3p4/8/8 w KQkq - 0 1";
  Board surrounded = Board(surroundedFEN);
  assert(surrounded.rookAttacks!(Color.White) == (C_4 | D_5 | D_3 | E_4));

  FEN longShotFEN = "p7/8/8/8/8/8/8/R6p w KQkq - 0 1";
  Board longShot = Board(longShotFEN);
  assert(longShot.rookAttacks!(Color.White) == (A_8 | H_1));
}

// whiteBishopMoves
unittest
{
  FEN middleFEN ="8/pppppppp/8/8/3B4/8/8/8 w KQkq - 0 1";
  Board middle = Board(middleFEN);
  auto middleMoves = C_5 | B_6 | E_5 | F_6 | C_3 | B_2 | A_1 | E_3 | F_2 | G_1;
  assert(middle.bishopMoves!(Color.White) == middleMoves);

  FEN surroundedFEN = "8/8/8/2p1p3/3B4/2p1p3/8/8 w KQkq - 0 1";
  Board surrounded = Board(surroundedFEN);
  assert(surrounded.bishopMoves!(Color.White)== 0L);
}

// whiteBishopAttacks
unittest
{
  FEN middleFEN ="8/pppppppp/8/8/3B4/8/8/8 w KQkq - 0 1";
  Board middle = Board(middleFEN);
  auto middleAttacks = A_7 | G_7;
  assert(middle.bishopAttacks!(Color.White) == middleAttacks);

  FEN surroundedFEN = "8/8/8/2p1p3/3B4/2p1p3/8/8 w KQkq - 0 1";
  Board surrounded = Board(surroundedFEN);
  assert(surrounded.bishopAttacks!(Color.White) == (C_5 | E_5 | C_3 | E_3));
}

// whiteQueenMoves
unittest
{
  FEN middleFEN ="8/pppppppp/8/8/3Q4/8/8/8 w KQkq - 0 1";
  Board middle = Board(middleFEN);

  auto middleRookMoves = A_4 | B_4 | C_4 | E_4 | F_4 | G_4 | G_4 | H_4 | D_1 | D_2 | D_3 | D_5 | D_6;
  auto middleBishopMoves = C_5 | B_6 | E_5 | F_6 | C_3 | B_2 | A_1 | E_3 | F_2 | G_1;
  auto middleMoves = middleRookMoves | middleBishopMoves;

  assert(middle.queenMoves!(Color.White) == middleMoves);

  FEN surroundedFEN = "8/8/8/2ppp3/2pQp3/2ppp3/8/8 w KQkq - 0 1";
  Board surrounded = Board(surroundedFEN);

  assert(surrounded.queenMoves!(Color.White) == 0L);
}

// whiteQueenAttacks
unittest
{
  FEN middleFEN ="8/pppppppp/8/8/3Q4/8/8/8 w KQkq - 0 1";
  Board middle = Board(middleFEN);

  assert(middle.queenAttacks!(Color.White) == (A_7 | D_7 | G_7));

  FEN surroundedFEN = "8/8/8/2ppp3/2pQp3/2ppp3/8/8 w KQkq - 0 1";
  Board surrounded = Board(surroundedFEN);
  assert(surrounded.queenAttacks!(Color.White) == (C_5 | D_5 | E_5 | C_4 | E_4 | C_3 | D_3 | E_3));
}
