with Ada.Text_IO.Unbounded_IO; use Ada.Text_IO.Unbounded_IO;
with Ada.Text_Io; use Ada.Text_Io;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Containers.Ordered_Sets;

procedure Hello is
  Line: Unbounded_String;
  Delimiter_Index: Natural;
  Start_Index: Natural;

  Token: Unbounded_String;

  Prior_Page: Natural;
  Subsequent_Page: Natural;

  package Set_of_Naturals is new Ada.Containers.Ordered_Sets(Element_Type => Natural);
  use Set_of_Naturals;

  Successor_Seen: Set_of_Naturals.Set := Set_of_Naturals.Empty_Set;

  package Map_Natural_to_Set_of_Naturals is new Ada.Containers.Ordered_Maps(Key_Type => Natural, Element_Type => Set_of_Naturals.Set, "=" => Set_of_Naturals."=");
  use Map_Natural_to_Set_of_Naturals;

  Page_Predecessors: Map_Natural_to_Set_of_Naturals.Map := Map_Natural_to_Set_of_Naturals.Empty_Map;

  Page_Cursor: Map_Natural_to_Set_of_Naturals.Cursor := Map_Natural_to_Set_of_Naturals.No_Element;

  Inserted_Successfully: Boolean;

  Current_Set: Set_of_Naturals.Set := Set_of_Naturals.Empty_Set;

  package Vector_of_Naturals is new Ada.Containers.Vectors(Index_Type => Natural, Element_Type => Natural);
  Page: Natural;
  Pages: Vector_of_Naturals.Vector := Vector_of_Naturals.Empty_Vector;

begin

  -- Get all the rules about predecessors and successors.
  Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);

  while Length(Line) > 0 loop
    Delimiter_Index := Index(Source => Line, Pattern => "|", From => 1);

    Token := To_Unbounded_String(Slice(Line, 1, Delimiter_Index-1));

    Prior_Page := Natural'Value(To_String(Token));

    Token := To_Unbounded_String(Slice(Line, Delimiter_Index+1, Length(Line)));

    Subsequent_Page := Natural'Value(To_String(Token));

    Page_Cursor := Page_Predecessors.Find(Subsequent_Page);
    if not Has_Element(Page_Cursor) then
      Page_Predecessors.Insert(Subsequent_Page, Set_of_Naturals.Empty_Set, Page_Cursor, Inserted_Successfully);
    end if;

    -- In order to add to a set within a map, we have to write a closure!
    declare 
      procedure Insert_Page(The_Key: in Natural; The_Set: in out Set_of_Naturals.Set) is
      begin
        The_Set.Insert(Prior_Page);
      end Insert_Page;
    begin
      -- Now we use the closure using the cumbersome Update_Element API.
      Page_Predecessors.Update_Element(Page_Cursor, Insert_Page'Access);
    end;

    Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);
  end loop;

  for Page_Cursor in Iterate(Page_Predecessors) loop
    Put_Line("Page" & Natural'Image(Key(Page_Cursor)) & " has" & Ada.Containers.Count_Type'Image(Length(Element(Page_Cursor))) & " predecessors");
  end loop;


  -- Now Page_Predecessors is loaded with all the info about the ordering rules.
  -- Page_Predecessors[Page_Num] is a Set that lists all the pages that must come before Page_Num.

  -- Now we read the actual list of ordered pages and see if they obey the rules.

  -- We have a Set of all pages for which we have seen one of their successors.
  -- When we consider a new page from a liat of pages, see if that page is in
  -- the Set.  If it is, we've seen one of that Page's successors, and so this
  -- ordering is not valid, because we saw a successor before the predecessor.

  -- But the first task is to read the line into a Vector.

  -- This program should be divided up into different procedures.  This would be a great boundary for one.
  -- It's too scary to figure out how to do that, though.

  loop
    Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);
    Start_Index := 1;

    Pages := Vector_of_Naturals.Empty_Vector;

    loop
      Delimiter_Index := Index(Source => Line, Pattern => ",", From => Start_Index);

      if Delimiter_Index > 0 then
        Token := To_Unbounded_String(Slice(Line, Start_Index, Delimiter_Index-1));
      else
        Token := To_Unbounded_String(Slice(Line, Start_Index, Length(Line)));
      end if;

      Page := Natural'Value(To_String(Token));

      Pages.Append(Page);
      Put_Line("Appended page" & Natural'Image(Page));

      Start_Index := Delimiter_Index+1;

      exit when Delimiter_Index = 0;
    end loop;

    Put_Line("Pages:" & Ada.Containers.Count_Type'Image(Pages.Length));

    exit when Length(Line) = 0;
  end loop;

end Hello;
