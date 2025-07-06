using System;

namespace HelloWorld {
  class Program {

    static void Main(string[] args) {
      List<string> Board = [];

      string? line;

      while ((line = Console.ReadLine()) != null) {
        Board.Add(line);
      }

      int x, y;
      int xmases_found = 0;

      // Let's do all the horizontals!
      for (y=0; y<Board.Count; y++) {
        for (x=0; x<=Board[0].Length-4; x++) {
          if ((Board[x][y] == 'X' && Board[x+1][y] == 'M' && Board[x+2][y] == 'A' && Board[x+3][y] == 'S')
              || (Board[x][y] == 'S' && Board[x+1][y] == 'A' && Board[x+2][y] == 'M' && Board[x+3][y] == 'X'))
          {
            xmases_found += 1;
          }
        }
      }

      // Now the verticals.
      for (y=0; y<=Board.Count-4; y++) {
        for (x=0; x<Board[0].Length; x++) {
          if ((Board[x][y] == 'X' && Board[x][y+1] == 'M' && Board[x][y+2] == 'A' && Board[x][y+3] == 'S')
              || (Board[x][y] == 'S' && Board[x][y+1] == 'A' && Board[x][y+2] == 'M' && Board[x][y+3] == 'X'))
          {
            xmases_found += 1;
          }
        }
      }

      // Now the diagonal down-rights.
      for (y=0; y<=Board.Count-4; y++) {
        for (x=0; x<=Board[0].Length-4; x++) {
          if ((Board[x][y] == 'X' && Board[x+1][y+1] == 'M' && Board[x+2][y+2] == 'A' && Board[x+3][y+3] == 'S')
              || (Board[x][y] == 'S' && Board[x+1][y+1] == 'A' && Board[x+2][y+2] == 'M' && Board[x+3][y+3] == 'X'))
          {
            xmases_found += 1;
          }
        }
      }

      // Now the diagonal down-lefts.
      for (y=0; y<=Board.Count-4; y++) {
        for (x=3; x<Board[0].Length; x++) {
          if ((Board[x][y] == 'X' && Board[x-1][y+1] == 'M' && Board[x-2][y+2] == 'A' && Board[x-3][y+3] == 'S')
              || (Board[x][y] == 'S' && Board[x-1][y+1] == 'A' && Board[x-2][y+2] == 'M' && Board[x-3][y+3] == 'X'))
          {
            xmases_found += 1;
          }
        }
      }

      Console.WriteLine($"Found {xmases_found} xmases");

    }

  }
}
