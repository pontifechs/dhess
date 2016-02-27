module dhess.Position;


enum Row: ubyte
{
  _1 = 0,
  _2 = 1,
  _3 = 2,
  _4 = 3,
  _5 = 4,
  _6 = 5,
  _7 = 6,
  _8 = 7
}

enum Column: ubyte
{
  A = 7,
  B = 6,
  C = 5,
  D = 4,
  E = 3,
  F = 2,
  G = 1,
  H = 0
}

mixin(genSquareEnum());

private string genSquareEnum()
{
  import std.conv;

  auto ret = "enum Square: ubyte {\n";

  for (int row = 0; row < 8; ++row)
  {
    for (int col = 0; col < 8; ++col)
    {
      Column colEnum = to!Column(col);
      auto name = colEnum.to!string ~ (row + 1).to!string ;
      auto value = (row * 8 + col).to!string;
      ret ~= "\t" ~ name ~ " = " ~ value ~ ",\n";
    }
  }

  ret ~= "}";
  return ret;
}

unittest
{
  assert(Square.A1 == 7);
  assert(Square.A8 == 63);
}
