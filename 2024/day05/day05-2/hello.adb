with Ada.Text_IO.Unbounded_IO; use Ada.Text_IO.Unbounded_IO;
with Ada.Text_Io; use Ada.Text_Io;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Containers.Ordered_Sets;
with Ada.Containers.Doubly_Linked_Lists;

procedure Hello is
  Line: Unbounded_String;
  Delimiter_Index: Natural;
  Start_Index: Natural;

  Token: Unbounded_String;

  Predecessor_Page: Natural;
  Successor_Page: Natural;

  package Set_of_Naturals is new Ada.Containers.Ordered_Sets(Element_Type => Natural);
  use Set_of_Naturals;

  package Map_Natural_to_Set_of_Naturals is new Ada.Containers.Ordered_Maps(Key_Type => Natural, Element_Type => Set_of_Naturals.Set, "=" => Set_of_Naturals."=");
  use Map_Natural_to_Set_of_Naturals;

  Successor_Seen: Map_Natural_to_Set_of_Naturals.Map := Empty_Map;

  Page_Predecessors: Map_Natural_to_Set_of_Naturals.Map := Empty_Map;

  Page_Map_Cursor: Map_Natural_to_Set_of_Naturals.Cursor := Map_Natural_to_Set_of_Naturals.No_Element;

  Inserted_Successfully: Boolean;

  Current_Set: Set_of_Naturals.Set := Empty_Set;

  package Linked_List_of_Naturals is new Ada.Containers.Doubly_Linked_Lists(Element_Type => Natural);
  use Linked_List_of_Naturals;
  Page: Natural;
  Pages: Linked_List_of_Naturals.List := Empty_List;
  Pages_Cursor: Linked_List_of_Naturals.Cursor := Linked_List_of_Naturals.No_Element;

  Layout_is_Good: Boolean := true;

  Predecessor_Cursor: Set_of_Naturals.Cursor := Set_of_Naturals.No_Element;

  Sum: Natural := 0;

  package Map_Natural_to_Cursor is new Ada.Containers.Ordered_Maps(Key_Type => Natural, Element_Type => Linked_List_of_Naturals.Cursor, "=" => Linked_List_of_Naturals."=");
  use Map_Natural_to_Cursor;
  Page_Catalog: Map_Natural_to_Cursor.Map := Map_Natural_to_Cursor.Empty_Map;
  Page_Catalog_Cursor: Map_Natural_to_Cursor.Cursor := Map_Natural_to_Cursor.No_Element;

  Successor_Page_Cursor: Linked_List_of_Naturals.Cursor;

begin

  -- Get all the rules about predecessors and successors.
  Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);

  while Length(Line) > 0 loop
    Delimiter_Index := Index(Source => Line, Pattern => "|", From => 1);

    Token := To_Unbounded_String(Slice(Line, 1, Delimiter_Index-1));

    Predecessor_Page := Natural'Value(To_String(Token));

    Token := To_Unbounded_String(Slice(Line, Delimiter_Index+1, Length(Line)));

    Successor_Page := Natural'Value(To_String(Token));

    Page_Map_Cursor := Page_Predecessors.Find(Successor_Page);
    if not Has_Element(Page_Map_Cursor) then
      Page_Predecessors.Insert(Successor_Page, Set_of_Naturals.Empty_Set, Page_Map_Cursor, Inserted_Successfully);
    end if;

    -- In order to add to a set within a map, we have to write a closure!
    declare 
      procedure Insert_Page(The_Key: in Natural; The_Set: in out Set_of_Naturals.Set) is
      begin
        The_Set.Insert(Predecessor_Page);
      end Insert_Page;
    begin
      -- Now we use the closure using the cumbersome Update_Element API.
      Page_Predecessors.Update_Element(Page_Map_Cursor, Insert_Page'Access);
    end;

    Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);
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

  while not End_of_File loop
    Line := Ada.Text_IO.Unbounded_IO.Get_Line(Standard_Input);

    Start_Index := 1;

    Pages := Linked_List_of_Naturals.Empty_List;
    Page_Catalog := Map_Natural_to_Cursor.Empty_Map;

    loop
      Delimiter_Index := Index(Source => Line, Pattern => ",", From => Start_Index);

      if Delimiter_Index > 0 then
        Token := To_Unbounded_String(Slice(Line, Start_Index, Delimiter_Index-1));
      else
        Token := To_Unbounded_String(Slice(Line, Start_Index, Length(Line)));
      end if;

      Page := Natural'Value(To_String(Token));

      Pages.Append(Page);
      Pages_Cursor := Pages.Last;

      Page_Catalog.Insert(Page, Pages_Cursor);

      Start_Index := Delimiter_Index+1;

      exit when Delimiter_Index = 0;
    end loop;

    -- We have read in an entire line of pages and placed them in the Pages vector.
    -- We have the rules in the Page_Predecessors map.
    -- We have the "successor seen" map to tell us, for each page, if we've seen a successor of that page.
    -- We have what we need to figure out if this page layout is valid.

    Layout_is_Good := true;
    Successor_Seen := Map_Natural_to_Set_of_Naturals.Empty_Map;

    Put("The list was   :");
    for Cool_Page in Pages.Iterate loop
      Put(Natural'Image(Element(Cool_Page)));
    end loop;
    Put_Line("");

    Pages_Cursor := Pages.First;
    while Has_Element(Pages_Cursor) loop
      Page := Linked_List_of_Naturals.Element(Pages_Cursor);

      Put_Line("Considering page" & Natural'Image(Page));

      -- If we've already seen a successor to this page, the layout is bad.
      if Has_Element(Successor_Seen.Find(Page)) then
        if Natural(Length(Element(Successor_Seen.Find(Page)))) > 0 then
          -- This is where we move pages around.
          -- We need to find the successor page that we've already seen, and we need to move it to the position in Pages after this page.
          -- This page is number Page, and it's located at Pages_Cursor.
          for Successor_Page in Element(Successor_Seen.Find(Page)).Iterate loop
            -- Find a cursor pointing to the successor page, and then use the linked list Splice interface to move it to be after Pages_Cursor.
            Successor_Page_Cursor := Element(Page_Catalog.Find(Element(Successor_Page)));

            Splice(Source => Pages, Target => Pages, Position => Successor_Page_Cursor, Before => Next(Pages_Cursor));

            -- Now we have to take the successor page out of the Successor_Seen list for every one of its predecessor pages.
            declare
              Current_Successor_Set: Set_of_Naturals.Set := Empty_Set;
              Current_Predecessor_Page: Natural;

              -- Declare a "delete the successor page" function so we can delete the successor page from a set inside a map.
              procedure Delete_Page(The_Key: in Natural; The_Set: in out Set_of_Naturals.Set) is
              begin
                if Has_Element(The_Set.Find(Element(Successor_Page))) then
                  The_Set.Delete(Element(Successor_Page));
                end if;
              end Delete_Page;

            begin
              for Current_Predecessor_Set_Cursor in Element(Page_Predecessors.Find(Element(Successor_Page))).Iterate loop
                Current_Predecessor_Page := Element(Current_Predecessor_Set_Cursor);
                if Has_Element(Successor_Seen.Find(Current_Predecessor_Page)) then
                  Successor_Seen.Update_Element(Successor_Seen.Find(Current_Predecessor_Page), Delete_Page'Access);
                end if;
              end loop;
            end;

            Put("The list is now:");
            for Cool_Page in Pages.Iterate loop
              Put(Natural'Image(Element(Cool_Page)));
            end loop;
            Put_Line("");
          end loop;
        end if;
      end if;
      exit when not Layout_is_Good;

      -- We haven't seen a successor to this page yet, so let's mark all of
      -- this page's predecessors and tell them that a successor has been seen.
      Page_Map_Cursor := Page_Predecessors.Find(Page);
      if Has_Element(Page_Map_Cursor) then
        Current_Set := Element(Page_Map_Cursor);
        for Predecessor_Cursor in Current_Set.Iterate loop
          Predecessor_Page := Element(Predecessor_Cursor);
          -- Insert this successor in the Successor_Seen set for this predecessor.
          if not Has_Element(Successor_Seen.Find(Predecessor_Page)) then 
            Successor_Seen.Insert(Predecessor_Page, Empty_Set);
          end if;

          -- In order to add to a set within a map, we have to write a closure!
          declare 
            procedure Insert_Page(The_Key: in Natural; The_Set: in out Set_of_Naturals.Set) is
            begin
              The_Set.Insert(Page);
            end Insert_Page;
          begin
            -- Now we use the closure using the cumbersome Update_Element API.
            Successor_Seen.Update_Element(Successor_Seen.Find(Predecessor_Page), Insert_Page'Access);
          end;
        end loop;
      end if;

      Pages_Cursor := Next(Pages_Cursor);
      
    end loop;

    if Layout_is_Good then
      Put_Line("Good");
    else
      Put_Line("Bad");
    end if;
    
--     if Layout_is_Good then
--       -- Find the middle page and add its number to the sum.
--       -- Vector_of_Naturals.Element(Pages, ((Length(Pages) / 2) + 1))
--       Page := Vector_of_Naturals.Element(Container => Pages, Index => (Natural(Pages.Length) / 2));
--       Put_Line("Adding" & Natural'Image(Page));
--       Sum := Sum + Page;
--     end if;
  end loop;

--   Put_Line("Sum:" & Natural'Image(Sum));

end Hello;
