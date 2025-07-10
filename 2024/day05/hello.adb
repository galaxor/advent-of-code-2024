with Ada.Text_IO.Unbounded_IO; use Ada.Text_IO.Unbounded_IO;
with Ada.Text_Io; use Ada.Text_Io;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;


procedure Hello is
  Line: Unbounded_String;
  Delimiter_Index: Natural;

  Token: Unbounded_String;

  Prior_Page: Natural;
  Subsequent_Page: Natural;
begin
  Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);

  Delimiter_Index := Index(Source => Line, Pattern => "|", From => 1);
  Put_Line("Cool num is: " & Natural'Image(Delimiter_Index));

  Token := To_Unbounded_String(Slice(Line, 1, Delimiter_Index-1));

  Put_Line("The first token is: " & Token);

  Prior_Page := Natural'Value(To_String(Token));

  Token := To_Unbounded_String(Slice(Line, Delimiter_Index+1, Length(Line)));

  Subsequent_Page := Natural'Value(To_String(Token));

  Put_Line("The second token is: " & Token);

  Put_Line("Numbers! " & Natural'Image(Prior_Page) & " + " & Natural'Image(Subsequent_Page) & " = " & Natural'Image(Prior_Page + Subsequent_Page));

end Hello;
