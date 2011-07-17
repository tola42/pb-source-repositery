;source : http://www.purebasic.fr/english/viewtopic.php?f=12&t=26729&hilit=+Here+the+default+language+is+specified+
;Author : freak
; -----------------------------------------------------------------
;   Example of a simple language management for programs
; -----------------------------------------------------------------
;
; Benefits of this solution:
;  - Strings are identified by a Group and Name string, which allows to
;    organize them with descriptive names and makes coding easier.
;
;  - Strings are sorted and indexed when they are loaded, which gives
;    a fast access even though they are accessed by name.
;
;  - A default language is defined in the code (DataSection), so even if
;    external language files are missing or outdated, there is always a
;    fallback string present.
;
;  - The list of strings is easy to extend. Simply add a new entry in the
;    DataSection and the language files and use the new Group and Name.
;
;  - Additional language files are in the PB Preference format which makes
;    them easy to maintain.
;
; Usage:
;  - define the default language in the DataSection like shown below
;  - Use LoadLanguage() at least once to load the default language or external file
;  - Use Language(Group$, Name$) to access the language strings
;
; -----------------------------------------------------------------

; Some misc stuff...
;
Global NbLanguageGroups, NbLanguageStrings

Structure LanguageGroup
  Name$
  GroupStart.l
  GroupEnd.l
  IndexTable.l[256]
EndStructure




; This procedure loads the language from a file, or the default language.
; It must be called at least once before using any language strings.
;
; It does this:
;  - load & sort the included default language
;  - load any additional language from file
;
; This way you always get a language string, even if the file is not found
; or a string entry is missing in the file. You will still get the default
; language when using tha Language() command.
;
; This function can be called multiple times to change the used language
; during runtime.
;
Procedure LoadLanguage(FileName$ = "")

  Protected Name$,String$,Group.l,StringIndex.l,i.l,char.l
  
  ; do a quick count in the datasection first:
  ;
  NbLanguageGroups = 0
  NbLanguageStrings = 0
  
  Restore Language
  Repeat
    
    Read.s  Name$
    Read.s  String$
    
    Name$ = UCase(Name$)
    
    If Name$ = "_GROUP_"
      NbLanguageGroups + 1
    ElseIf Name$ = "_END_"
      Break
    Else
      NbLanguageStrings + 1
    EndIf
    
  ForEver
  ;On cr�er le fichier
  
  
  Global Dim LanguageGroups.LanguageGroup(NbLanguageGroups)  ; all one based here
  Global Dim LanguageStrings.s(NbLanguageStrings)
  Global Dim LanguageNames.s(NbLanguageStrings)
  
  ; Now load the standard language:
  ;
  Group = 0
  StringIndex = 0
  
  Restore Language
  Repeat
    
    Read.s Name$
    Read.s String$
    
    Name$ = UCase(Name$)
    
    If Name$ = "_GROUP_"
      LanguageGroups(Group)\GroupEnd = StringIndex
      Group + 1
      
      LanguageGroups(Group)\Name$ = UCase(String$)
      ;On cr��er le nouveau groupe
     
      
      
      LanguageGroups(Group)\GroupStart = StringIndex + 1
      For i = 0 To 255
        LanguageGroups(Group)\IndexTable[i] = 0
      Next i
      
    ElseIf Name$ = "_END_"
      Break
      
    Else
      StringIndex + 1
      LanguageNames(StringIndex) = Name$ + Chr(1) + String$  ; keep name and string together for easier sorting
      ;On sauvegarde les nouvelles clef
      
    EndIf
    
  ForEver
  
  
  
  LanguageGroups(Group)\GroupEnd   = StringIndex ; set end for the last group!
 
  ; Now do the sorting and the indexing for each group
  ;
  For Group = 1 To NbLanguageGroups
    If LanguageGroups(Group)\GroupStart <= LanguageGroups(Group)\GroupEnd  ; sanity check.. check for empty groups
     
      SortArray(LanguageNames(), 0, LanguageGroups(Group)\GroupStart, LanguageGroups(Group)\GroupEnd)
 
      char = 0
      For StringIndex = LanguageGroups(Group)\GroupStart To LanguageGroups(Group)\GroupEnd
        LanguageStrings(StringIndex) = StringField(LanguageNames(StringIndex), 2, Chr(1)) ; splitt the value from the name
        LanguageNames(StringIndex)   = StringField(LanguageNames(StringIndex), 1, Chr(1))

        If Asc(Left(LanguageNames(StringIndex), 1)) <> char
          char = Asc(Left(LanguageNames(StringIndex), 1))
          LanguageGroups(Group)\IndexTable[char] = StringIndex
        EndIf
      Next StringIndex
     
    EndIf
  Next Group

  ; Now try to load an external language file
  ;       
  If FileName$ <> ""
     
    If OpenPreferences(FileName$)
      For Group = 1 To NbLanguageGroups
        If LanguageGroups(Group)\GroupStart <= LanguageGroups(Group)\GroupEnd  ; sanity check.. check for empty groups
          PreferenceGroup(LanguageGroups(Group)\Name$)
         
          For StringIndex = LanguageGroups(Group)\GroupStart To LanguageGroups(Group)\GroupEnd
            LanguageStrings(StringIndex) = ReadPreferenceString(LanguageNames(StringIndex), LanguageStrings(StringIndex))
          Next StringIndex
        EndIf
      Next Group
      ClosePreferences()   
     
      ProcedureReturn #True
    EndIf   

  EndIf
 
  ProcedureReturn #True
EndProcedure


; This function returns a string in the current language
; Each string is identified by a Group and a Name (both case insensitive)
;
; If the string is not found (not even in the included default language), the
; return is "##### String not found! #####" which helps to spot errors in the
; language code easily.
;
Procedure.s Language(Group$, Name$)
  Static Group.l  ; for quicker access when using the same group more than once
  Protected String$, StringIndex, Result
  
  Group$ = UCase(Group$)
  Name$ = UCase(Name$)
  String$ = Name$ + " [String not found in " + Chr(34) + Group$ + Chr(34) + "]"  ; to help find bugs
  
  If LanguageGroups(Group)\Name$<>Group$  ; check if it is the same group as last time
    For Group = 1 To NbLanguageGroups
      If Group$ = LanguageGroups(Group)\Name$
        Break
      EndIf
    Next Group
    
    If Group>NbLanguageGroups  ; check if group was found
      Group = 0
    EndIf
  EndIf
  
  If Group<>0
    StringIndex = LanguageGroups(Group)\IndexTable[Asc(Left(Name$, 1)) ]
    If StringIndex<>0
      
      Repeat
        Result = CompareMemoryString(@Name$, @LanguageNames(StringIndex))
        
        If Result = 0
          String$ = LanguageStrings(StringIndex)
          Break
          
        ElseIf Result = -1 ; string not found!
          Break
          
        EndIf
        
        StringIndex + 1
      Until StringIndex>LanguageGroups(Group)\GroupEnd
      
    EndIf
    
  EndIf
  
  ProcedureReturn String$
EndProcedure

loadLanguage("")

Procedure SaveLanguageAsModel(Name.s)
  Protected z.l, StringIndex.l
  If CreatePreferences(Name.s)
    For z = 1 To NbLanguageGroups
      PreferenceGroup(LanguageGroups(z)\Name$)
      StringIndex = 0;
      For StringIndex = LanguageGroups(z)\GroupStart To LanguageGroups(z)\GroupEnd
        WritePreferenceString(LanguageNames(StringIndex), LanguageStrings(StringIndex))
      Next
    Next
    ClosePreferences()
  EndIf
EndProcedure

; -----------------------------------------------------------------
; Example:
; -----------------------------------------------------------------

;LoadLanguage("fran�ais.txt",#False)                ; load default language
;LoadLanguage("german.prefs") ; uncomment this to load the german file

; get some language strings
;
;Debug Language("MenuTitle", "Edit")
;Debug Language("MenuItem", "Save")

; -----------------------------------------------------------------
; IDE Options = PureBasic 4.60 Beta 3 (Windows - x86)
; CursorPosition = 230
; FirstLine = 189
; Folding = -
; EnableXP
; UseMainFile = main.pb