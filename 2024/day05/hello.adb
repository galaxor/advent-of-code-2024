with Ada.Text_IO.Unbounded_IO; use Ada.Text_IO.Unbounded_IO;
with Ada.Text_Io; use Ada.Text_Io;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Containers.Ordered_Sets;

procedure Hello is
  Line: Unbounded_String;
  Delimiter_Index: Natural;

  Token: Unbounded_String;

  Prior_Page: Natural;
  Subsequent_Page: Natural;

  package Set_of_Naturals is new Ada.Containers.Ordered_Sets(Element_Type => Natural);
  use Set_of_Naturals;

  Pages_Seen_Map: Set_of_Naturals.Set := Set_of_Naturals.Empty_Set;
  Successor_Seen: Set_of_Naturals.Set := Set_of_Naturals.Empty_Set;

  package Map_Natural_to_Set_of_Naturals is new Ada.Containers.Ordered_Maps(Key_Type => Natural, Element_Type => Set_of_Naturals.Set, "=" => Set_of_Naturals."=");
  use Map_Natural_to_Set_of_Naturals;

  Page_Predecessors: Map_Natural_to_Set_of_Naturals.Map := Map_Natural_to_Set_of_Naturals.Empty_Map;
  Page_Successors: Map_Natural_to_Set_of_Naturals.Map := Map_Natural_to_Set_of_Naturals.Empty_Map;

  Page_Cursor: Map_Natural_to_Set_of_Naturals.Cursor := Map_Natural_to_Set_of_Naturals.No_Element;

  Inserted_Successfully: Boolean;

  Current_Set: Set_of_Naturals.Set := Set_of_Naturals.Empty_Set;

begin

  -- Get all the rules about predecessors and successors.
  Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);

  while Length(Line) > 0 loop
    Delimiter_Index := Index(Source => Line, Pattern => "|", From => 1);

    Token := To_Unbounded_String(Slice(Line, 1, Delimiter_Index-1));

    Put_Line("The first token is: " & Token);

    Prior_Page := Natural'Value(To_String(Token));

    Token := To_Unbounded_String(Slice(Line, Delimiter_Index+1, Length(Line)));

    Subsequent_Page := Natural'Value(To_String(Token));

    Put_Line("Numbers! " & Natural'Image(Prior_Page) & " + " & Natural'Image(Subsequent_Page) & " = " & Natural'Image(Prior_Page + Subsequent_Page));

    Page_Cursor := Find(Page_Predecessors, Subsequent_Page);
    if not Has_Element(Page_Cursor) then
      Insert(Page_Predecessors, Subsequent_Page, Set_of_Naturals.Empty_Set, Page_Cursor, Inserted_Successfully);
    end if;

    -- In order to add to a set within a map, we have to write a closure!
    declare 
      procedure Insert_Page(The_Key: in Natural; The_Set: in out Set_of_Naturals.Set) is
      begin
        Insert(The_Set, Prior_Page);
      end Insert_Page;
    begin
      -- Now we use the closure using the cumbersome Update_Element API.
      Update_Element(Page_Predecessors, Page_Cursor, Insert_Page'Access);
    end;

    Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);
  end loop;

  for Page_Cursor in Iterate(Page_Predecessors) loop
    Put_Line("Page" & Natural'Image(Key(Page_Cursor)) & " has" & Ada.Containers.Count_Type'Image(Length(Element(Page_Cursor))) & " predecessors");
  end loop;

end Hello;
